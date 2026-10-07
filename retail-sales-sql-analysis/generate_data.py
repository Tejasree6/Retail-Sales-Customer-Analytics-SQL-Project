"""
Generates a reproducible synthetic retail dataset and loads it into SQLite.
Run:  python generate_data.py
Output: retail.db  (+ CSV copies in /data)

NOTE: The data is synthetic (random seed = 42). To use a real dataset instead,
keep schema.sql and load your own CSVs into the same four tables.
"""
import csv, random, sqlite3, os
from datetime import date, timedelta

random.seed(42)

CITIES = [("Hyderabad","Telangana"),("Chennai","Tamil Nadu"),("Bengaluru","Karnataka"),
          ("Mumbai","Maharashtra"),("Delhi","Delhi"),("Kolkata","West Bengal"),
          ("Pune","Maharashtra"),("Tirupati","Andhra Pradesh"),("Visakhapatnam","Andhra Pradesh"),
          ("Coimbatore","Tamil Nadu"),("Jaipur","Rajasthan"),("Bhubaneswar","Odisha")]
CITY_W = [14,12,14,13,12,7,8,3,5,4,4,4]
SEGMENTS = ["Consumer","Corporate","Small Business"]
SEG_W = [60,20,20]
FIRST = ["Aarav","Vivaan","Aditya","Sai","Arjun","Krishna","Rohan","Karthik","Anil","Ravi",
         "Ananya","Diya","Priya","Sneha","Lakshmi","Divya","Meena","Kavya","Pooja","Neha"]
LAST = ["Reddy","Sharma","Iyer","Nair","Patel","Rao","Gupta","Singh","Kumar","Naidu","Das","Menon"]

CATALOG = {
 "Electronics":[("Mobile Phone","Smartphones",9000,14000),("Earbuds","Audio",600,1500),
                ("Power Bank","Accessories",500,1100),("Smart Watch","Wearables",1500,3200),
                ("Bluetooth Speaker","Audio",900,2200),("Laptop","Computers",28000,42000),
                ("Tablet","Computers",9000,15000),("USB Cable","Accessories",80,250)],
 "Fashion":[("Men Casual Shirt","Menswear",350,900),("Women Kurta","Womenswear",400,1100),
            ("Running Shoes","Footwear",900,2400),("Jeans","Menswear",500,1400),
            ("Saree","Womenswear",700,2200),("Backpack","Accessories",300,900),
            ("Sunglasses","Accessories",200,800),("Sneakers","Footwear",800,2000)],
 "Home & Kitchen":[("Mixer Grinder","Appliances",1400,3000),("Pressure Cooker","Cookware",600,1500),
                   ("Bedsheet Set","Furnishing",350,1100),("Water Bottle","Cookware",120,400),
                   ("LED Bulb Pack","Lighting",150,450),("Air Fryer","Appliances",2500,5200),
                   ("Dinner Set","Cookware",800,2200),("Curtains","Furnishing",300,900)],
 "Books & Stationery":[("Data Analytics Book","Books",250,600),("Notebook Pack","Stationery",60,180),
                       ("Fiction Novel","Books",120,350),("Pen Set","Stationery",40,150),
                       ("Planner Diary","Stationery",100,300),("Exam Guide","Books",150,450)],
 "Beauty & Health":[("Face Wash","Skincare",70,220),("Moisturiser","Skincare",120,400),
                    ("Shampoo","Haircare",100,320),("Protein Powder","Nutrition",900,2200),
                    ("Vitamin Tablets","Nutrition",200,550),("Perfume","Fragrance",300,1100)],
}
PAY = ["UPI","Card","COD","NetBanking"]; PAY_W = [45,25,22,8]

os.makedirs("data", exist_ok=True)

# ---- customers
customers = []
for cid in range(1, 501):
    city, state = random.choices(CITIES, CITY_W)[0]
    signup = date(2022,1,1) + timedelta(days=random.randint(0, 900))
    customers.append((cid, f"{random.choice(FIRST)} {random.choice(LAST)}", city, state,
                      random.choices(SEGMENTS, SEG_W)[0], signup.isoformat()))

# ---- products
products, pid = [], 1
for cat, items in CATALOG.items():
    for name, sub, cost, price in items:
        products.append((pid, name, cat, sub, cost, price)); pid += 1

# ---- orders + items
orders, items, oid, iid = [], [], 1, 1
end = date(2024,12,31)
for c in customers:
    signup = date.fromisoformat(c[5])
    n_orders = max(0, int(random.expovariate(1/6)))      # skewed: few heavy buyers
    for _ in range(n_orders):
        if signup > end: break
        od = signup + timedelta(days=random.randint(0, (end - signup).days))
        # seasonality: extra orders pushed into Oct-Nov (festive season)
        if random.random() < 0.15:
            od = date(od.year, random.choice([10,11]), random.randint(1,28))
            if od < signup: od = signup
        sd = od + timedelta(days=random.randint(1,7))
        status = random.choices(["Delivered","Returned","Cancelled"],[88,7,5])[0]
        orders.append((oid, c[0], od.isoformat(), sd.isoformat(), status,
                       random.choices(PAY, PAY_W)[0]))
        for _ in range(random.choices([1,2,3,4],[55,28,12,5])[0]):
            p = random.choice(products)
            disc = random.choices([0,0.05,0.10,0.15,0.20,0.30],[40,20,18,10,8,4])[0]
            items.append((iid, oid, p[0], random.choices([1,2,3],[75,18,7])[0], p[5], disc))
            iid += 1
        oid += 1

# ---- write CSVs
def dump(name, header, rows):
    with open(f"data/{name}.csv","w",newline="") as f:
        w = csv.writer(f); w.writerow(header); w.writerows(rows)
dump("customers",["customer_id","customer_name","city","state","segment","signup_date"],customers)
dump("products",["product_id","product_name","category","sub_category","unit_cost","unit_price"],products)
dump("orders",["order_id","customer_id","order_date","ship_date","order_status","payment_method"],orders)
dump("order_items",["order_item_id","order_id","product_id","quantity","unit_price","discount_pct"],items)

# ---- load into SQLite
if os.path.exists("retail.db"): os.remove("retail.db")
con = sqlite3.connect("retail.db")
con.executescript(open("schema.sql").read())
con.executemany("INSERT INTO customers VALUES (?,?,?,?,?,?)", customers)
con.executemany("INSERT INTO products VALUES (?,?,?,?,?,?)", products)
con.executemany("INSERT INTO orders VALUES (?,?,?,?,?,?)", orders)
con.executemany("INSERT INTO order_items VALUES (?,?,?,?,?,?)", items)
con.commit()
for t in ["customers","products","orders","order_items"]:
    print(t, con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0])
con.close()
