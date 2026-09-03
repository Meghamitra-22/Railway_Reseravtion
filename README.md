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
## Example Queries

The project includes example SQL queries for:
- Finding all trains starting from New Delhi
- Displaying the complete route of a particular train
- Viewing all booked tickets with passenger details

---

