"""
Generates a synthetic, deliberately messy eCommerce events dataset.
Same columns as the Kaggle "eCommerce behavior data" so the SQL carries over.
Run:  python generate_data.py   ->  data/events.csv
"""
import random, zlib
from datetime import datetime, timedelta
import numpy as np
import pandas as pd

random.seed(42)
np.random.seed(42)

N_USERS = 12_000
START = datetime(2019, 10, 1)

# category -> (brands, price range, cart prob, purchase-given-cart prob)
CATEGORIES = {
    "electronics.smartphone":   (["samsung", "apple", "xiaomi", "huawei"], (120, 1200), 0.14, 0.30),
    "electronics.audio.headphone": (["sony", "jbl", "apple", "xiaomi"],    (15, 350),   0.12, 0.38),
    "electronics.video.tv":     (["samsung", "lg", "sony", "philips"],     (200, 1500), 0.08, 0.22),
    "computers.notebook":       (["lenovo", "hp", "asus", "acer", "dell"], (300, 2000), 0.09, 0.20),
    "appliances.kitchen.blender": (["bosch", "philips", "braun"],          (25, 180),   0.13, 0.42),
    "appliances.environment.vacuum": (["dyson", "bosch", "xiaomi"],        (60, 700),   0.10, 0.33),
    "apparel.shoes":            (["nike", "adidas", "puma", "reebok"],     (30, 220),   0.17, 0.45),
    "apparel.tshirt":           (["nike", "adidas", "puma", "levis"],      (10, 70),    0.20, 0.50),
    "furniture.living_room.sofa": (["ikea", "hatsan", "bellona"],          (150, 1400), 0.06, 0.15),
    "sport.bicycle":            (["trek", "giant", "merida"],              (150, 1800), 0.07, 0.18),
    "kids.toys":                (["lego", "mattel", "fisher-price"],       (8, 120),    0.22, 0.52),
    "accessories.bag":          (["samsonite", "xiaomi", "nike"],          (15, 250),   0.15, 0.40),
}
HOUR_WEIGHTS = np.array([2,1,1,1,1,2,3,5,7,8,9,9,9,8,8,8,9,10,12,13,12,9,6,3], float)
HOUR_WEIGHTS /= HOUR_WEIGHTS.sum()

# product catalogue
products = []
pid = 1_000_000
for cat, (brands, (lo, hi), _, _) in CATEGORIES.items():
    for _ in range(40):
        products.append({
            "product_id": pid, "category_code": cat,
            "category_id": 2_053_013_550_000_000_000 + zlib.crc32(cat.encode()) % 10**9,
            "brand": random.choice(brands),
            "price": round(random.uniform(lo, hi), 2),
        })
        pid += 1
prod_df = pd.DataFrame(products)
weights = np.random.pareto(1.2, len(prod_df)) + 1   # some products far more popular
weights /= weights.sum()

rows = []
def ev(t, typ, p, uid, sess):
    rows.append([t, typ, p["product_id"], p["category_id"], p["category_code"],
                 p["brand"], p["price"], uid, sess])

for u in range(N_USERS):
    uid = 500_000_000 + u * 7
    is_mobile_heavy = random.random() < 0.5
    n_sessions = np.random.choice([1,2,3,4,5,6], p=[.45,.25,.14,.08,.05,.03])
    for _ in range(n_sessions):
        day = int(np.random.choice(31, p=np.array([1.2 if (START+timedelta(days=d)).weekday()>=5 else 1.0 for d in range(31)]) / sum(1.2 if (START+timedelta(days=d)).weekday()>=5 else 1.0 for d in range(31))))
        hour = int(np.random.choice(24, p=HOUR_WEIGHTS))
        t = START + timedelta(days=day, hours=hour, minutes=random.randint(0,59), seconds=random.randint(0,59))
        sess = f"{random.getrandbits(128):032x}"
        n_views = int(min(1 + np.random.geometric(0.28), 25))
        for _v in range(n_views):
            p = prod_df.iloc[np.random.choice(len(prod_df), p=weights)].to_dict()
            t += timedelta(seconds=random.randint(5, 180))
            ev(t, "view", p, uid, sess)
            _, _, cart_p, buy_p = CATEGORIES[p["category_code"]]
            if random.random() < cart_p:
                t += timedelta(seconds=random.randint(10, 300))
                ev(t, "cart", p, uid, sess)
                if random.random() < 0.18:
                    t += timedelta(seconds=random.randint(10, 200))
                    ev(t, "remove_from_cart", p, uid, sess)
                elif random.random() < buy_p:
                    t += timedelta(seconds=random.randint(30, 1800))
                    ev(t, "purchase", p, uid, sess)

# a few bot users with thousands of views and no purchases
for b in range(4):
    uid = 900_000_000 + b
    sess = f"{random.getrandbits(128):032x}"
    t = START + timedelta(days=random.randint(0, 30))
    for _ in range(2500):
        p = prod_df.iloc[random.randrange(len(prod_df))].to_dict()
        t += timedelta(seconds=1)
        ev(t, "view", p, uid, sess)

df = pd.DataFrame(rows, columns=["event_time","event_type","product_id","category_id",
                                 "category_code","brand","price","user_id","user_session"])
n = len(df)

# ---------- add the mess ----------
# 1. timestamps: standard format, with ~1% in a different format
fmt_std = df["event_time"].dt.strftime("%Y-%m-%d %H:%M:%S UTC")
fmt_iso = df["event_time"].dt.strftime("%Y-%m-%dT%H:%M:%SZ")
df["event_time"] = np.where(np.random.rand(n) < 0.01, fmt_iso, fmt_std)

# 2. missing brand (~22%) and missing category (~12%)
df.loc[np.random.rand(n) < 0.22, "brand"] = np.nan
df.loc[np.random.rand(n) < 0.12, "category_code"] = np.nan

# 3. inconsistent brand/event_type casing and whitespace
def messy_text(s):
    r = random.random()
    if r < 0.03: return s.upper()
    if r < 0.06: return s.title()
    if r < 0.08: return " " + s + " "
    return s
mask = df["brand"].notna()
df.loc[mask, "brand"] = df.loc[mask, "brand"].map(messy_text)
df["event_type"] = df["event_type"].map(
    lambda s: s.upper() if random.random() < 0.004 else (s.title() if random.random() < 0.004 else s))

# 4. bad prices: zero, negative, extreme outliers, missing
r = np.random.rand(n)
df.loc[r < 0.004, "price"] = 0
df.loc[(r >= 0.004) & (r < 0.007), "price"] = -df["price"].abs()
df.loc[(r >= 0.007) & (r < 0.0085), "price"] = df["price"] * 100
df.loc[(r >= 0.0085) & (r < 0.0125), "price"] = np.nan

# 5. missing user_id (~0.5%)
df["user_id"] = df["user_id"].astype("Int64")
df.loc[np.random.rand(n) < 0.005, "user_id"] = pd.NA

# 6. duplicate rows (~2%) and shuffled order
dups = df.sample(frac=0.02, random_state=1)
df = pd.concat([df, dups]).sample(frac=1, random_state=2).reset_index(drop=True)

df.to_csv("data/events.csv", index=False)
print(f"Wrote data/events.csv with {len(df):,} rows")
