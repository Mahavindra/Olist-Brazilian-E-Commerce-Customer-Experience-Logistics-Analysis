# 📦 Olist Brazilian E-Commerce: Customer Experience & Logistics Analysis

## 🎯 Executive Summary
Analyzed 95,830 filtered orders from the Brazilian Olist e-commerce dataset to identify drivers of customer dissatisfaction. Discovered that delivery delays are the single largest factor driving 1-star reviews, with late rates spiking from 1.86% (5-star reviews) to 36.78% (1-star reviews). Isolated regional logistics bottlenecks and identified high-volume sellers driving platform-wide satisfaction drops.

---

## 🛠️ Tech Stack & Methodology
* **Database Engine:** MySQL 8.0
  * Standardized text-formatted dates (`STR_TO_DATE`) and handled `NULL` review scores.
  * Evaluated dataset granularity across line items, payments, reviews, and customers.
  * Built two modular `VIEW` structures (`customer_experience_foundation` and `seller_order_foundation`) to handle single vs. multi-seller order logic.
* **BI & Visualization:** Power BI Desktop
  * Engineered DAX measures (`Total Orders`, `Late Orders`, `Late Rate %`, `Avg Rating`).
  * Created custom DAX calculated columns (`Delivery_Status`, `Review_Star_Bin`).
  * Designed a 3-column executive layout (*Executive Overview*, *State Overview*, *Seller Overview*).

---

## 📊 Key Business Findings

![Dashboard Preview](Olist%20Customer%20Experience%20%26%20Delivery%20Performance%20Dashboard%20Preview.png)

1. **Satisfaction vs. Delivery Delays:** Delivery lateness directly triggers low review scores. Late rate increases monotonically from **1.86%** on 5-star reviews to **36.78%** on 1-star reviews.
2. **Order Complexity Impact:** Multi-seller orders experience lower customer satisfaction scores despite showing shorter delivery lead times, indicating multi-package arrival friction.
3. **Geographic Bottlenecks:** States such as **Rio de Janeiro (RJ - 11.92% late rate)** and **Bahia (BA - 11.89% late rate)** suffer from significantly higher lateness than the national baseline (**6.66%**).
4. **Seller Level Friction:** Satisfaction drops are concentrated among specific high-volume merchants with late delivery rates exceeding **20%**.

---

## 📁 Repository Structure
* [`brazilian_ecommerce_EDA.sql`](brazilian_ecommerce_EDA.sql) — Data cleaning, validation, view creation, and EDA queries.
* [`Olist Customer Experience and Delivery Performance.pbix`](Olist%20Customer%20Experience%20and%20Delivery%20Performance.pbix) — Interactive Power BI report file.
* [`Olist Customer Experience & Delivery Performance Dashboard Preview.png`](Olist%20Customer%20Experience%20%26%20Delivery%20Performance%20Dashboard%20Preview.png) — High-resolution executive dashboard screenshot.
