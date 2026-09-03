# 🚆 Ticket Reservation System — MySQL

A database-driven **Indian Railways-style Ticket Reservation System** built using **MySQL 8.0**.

The project models railway reservations using a relational database and implements ticket booking, seat allocation, RAC/waitlist management, cancellations, refunds, PNR status checking, passenger lists, and revenue/refund reports.

---

## 🛠️ Tech Stack

* **Database:** MySQL 8.0
* **Language:** SQL
* **Storage Engine:** InnoDB
* **Core Concepts:**

  * Relational database design
  * Primary & foreign keys
  * Transactions
  * Row-level locking
  * Stored procedures
  * Error handling
  * Indexing
  * Constraints

---

## ✨ Features

### 🚆 Train Management

* Store train information
* Store source and destination stations
* Define ordered train routes
* Track departure and arrival times
* Configure train operating days

### 🎫 Ticket Booking

* Book tickets for individual passengers
* Automatically generate PNR numbers
* Calculate fare based on:

  * Travel distance
  * Train base fare
  * Travel class
* Support passenger categories such as:

  * General
  * Senior Citizen
  * Ladies
  * Disabled
  * Armed Forces

### 💺 Seat Allocation

Tickets are allocated using the following priority:

```text
CONFIRMED → RAC → WAITLIST
```

The system maintains separate inventory for:

* Confirmed seats
* RAC capacity
* RAC bookings
* Waiting list

### 🔄 Cancellation & Promotion

When a ticket is cancelled:

```text
Confirmed cancellation
        ↓
RAC passenger promoted to Confirmed
        ↓
Waiting-list passenger promoted to RAC
```

For RAC cancellation:

```text
RAC cancellation
        ↓
Waiting-list passenger promoted to RAC
```

The system also calculates cancellation charges and records refunds.

### 🔎 PNR Status

Retrieve complete ticket information using the PNR number, including:

* Passenger details
* Train
* Class
* Travel date
* Source
* Destination
* Ticket status
* Seat/coach
* Fare
* RAC/WL number

### 📊 Reports

The system provides:

* Passenger lists
* Seat availability
* Revenue reports
* Refund reports

---

## 🗄️ Database Schema

The database contains the following major tables:

| Table           | Purpose                               |
| --------------- | ------------------------------------- |
| `stations`      | Railway station information           |
| `class`         | Travel classes and fare multipliers   |
| `trains`        | Train details                         |
| `routes`        | Ordered train stoppages and distances |
| `passengers`    | Passenger information                 |
| `seat`          | Seat inventory by train/class/date    |
| `ticket`        | Ticket and booking information        |
| `payment`       | Payment records                       |
| `rac_info`      | RAC ticket information                |
| `wl_info`       | Waiting-list information              |
| `refund_record` | Cancellation and refund records       |

---

## ⚙️ Stored Procedures

The project includes the following stored procedures:

### `book_tickets`

Books a passenger and automatically determines whether the ticket is:

* CONFIRMED
* RAC
* WL

It also calculates the fare, creates the passenger and ticket records, records payment, and generates/reuses a PNR.

### `cancel_ticket`

Cancels a ticket, calculates the cancellation charge, creates a refund record, updates inventory, and promotes RAC/WL passengers where applicable.

### `get_trains_by_date`

Returns trains operating on a specified date.

### `CheckPNRStatus`

Returns complete booking information for a given PNR.

### `GetAvailableSeats`

Displays confirmed, RAC, and waitlist availability.

### `GetPassengerList`

Returns passengers booked on a particular train and travel date.

### `GetRevenueReport`

Generates train-wise revenue information for a specified date range.

### `GetRefundReport`

Returns refund information for a specified date range.

---

## 🔐 Database & Concurrency Concepts

The booking procedure uses a transaction and row-level locking to protect seat inventory during booking.

The relevant seat-inventory row is locked using:

```sql
SELECT ...
FROM seat
WHERE train_id = ...
  AND class_id = ...
  AND travel_date = ...
FOR UPDATE;
```

This helps prevent conflicting updates to the same seat inventory during concurrent transactions.

The project also uses `SIGNAL` for database-level error handling and rolls back transactions when an SQL exception occurs.

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/ticket-reservation-system.git
cd ticket-reservation-system
```

### 2. Open MySQL

Run the SQL script:

```sql
SOURCE ticket_reservation_system.sql;
```

Or open the `.sql` file in MySQL Workbench and execute it.

The script creates the database:

```text
miniproject
```

and populates it with sample stations, trains, routes, classes, and seat inventory.

---

# 🧪 Queries to Try

After executing the SQL file, try the following queries.

## 1. View all stations

```sql
USE miniproject;

SELECT *
FROM stations;
```

---

## 2. View all trains

```sql
SELECT *
FROM trains;
```

---

## 3. View train routes

```sql
SELECT 
    t.train_number,
    t.train_name,
    s.station_name,
    r.seq_no,
    r.arrival_time,
    r.departure_time,
    r.distance_from_source_km
FROM routes r
JOIN trains t 
    ON r.train_id = t.train_id
JOIN stations s 
    ON r.station_id = s.station_id
ORDER BY t.train_number, r.seq_no;
```

---

## 4. Find trains running on a particular date

```sql
CALL get_trains_by_date('2026-09-10');
```

---

## 5. Check seat availability

For train `12301`, Sleeper class, on September 10:

```sql
CALL GetAvailableSeats(1, 1, '2026-09-10');
```

---

## 6. Book a confirmed ticket

```sql
SET @pnr = NULL;

CALL book_tickets(
    'Ravi Kumar',
    34,
    'M',
    'GENERAL',
    1,
    1,
    '2026-09-10',
    1,
    5,
    @pnr,
    @status,
    @ticket_id
);

SELECT 
    @pnr AS pnr,
    @status AS status,
    @ticket_id AS ticket_id;
```

The first booking should receive a **CONFIRMED** status because seats are initially available.

---

## 7. Book another passenger under the same PNR

```sql
CALL book_tickets(
    'Sita Kumar',
    30,
    'F',
    'GENERAL',
    1,
    1,
    '2026-09-10',
    1,
    5,
    @pnr,
    @status2,
    @ticket_id2
);

SELECT 
    @pnr AS pnr,
    @status2 AS status,
    @ticket_id2 AS ticket_id;
```

This demonstrates how multiple passengers can share the same PNR.

---

## 8. Check PNR status

```sql
CALL CheckPNRStatus(@pnr);
```

---

## 9. View passengers booked on a train

```sql
CALL GetPassengerList(1, '2026-09-10');
```

---

## 10. Cancel a ticket

```sql
CALL cancel_ticket(@ticket_id);
```

Then check the PNR again:

```sql
CALL CheckPNRStatus(@pnr);
```

---

## 11. Check updated seat availability

```sql
CALL GetAvailableSeats(1, 1, '2026-09-10');
```

---

## 12. Generate a revenue report

```sql
CALL GetRevenueReport(
    '2026-09-01',
    '2026-09-30'
);
```

---

## 13. Generate a refund report

```sql
CALL GetRefundReport(
    '2026-09-01',
    '2026-09-30'
);
```

---

# 📁 Project Structure

```text
ticket-reservation-system/
│
├── ticket_reservation_system.sql
└── README.md
```

---

## 📌 Notes

This project is intended as a database-focused implementation of a railway ticket reservation system. The SQL script includes both schema creation and sample data so that the stored procedures can be tested immediately after importing the database.

---

## 👩‍💻 Author

**Meghamitra Chowdhury**

B.Tech — Chemical Engineering
Indian Institute of Technology Patna

