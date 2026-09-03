-- =====================================================================
--  TICKET RESERVATION SYSTEM (Indian Railways style) - MySQL
--  Full schema + sample data + stored procedures
--  Tested against MySQL 8.0 (uses SET column, window-free logic,
--  FOR UPDATE row locking, SIGNAL for error handling)
-- =====================================================================

DROP DATABASE IF EXISTS miniproject;
CREATE DATABASE miniproject;
USE miniproject;

-- =====================================================================
-- 1. TABLES
-- =====================================================================

-- ---------------------------------------------------------------------
-- stations
-- ---------------------------------------------------------------------
CREATE TABLE stations (
    station_id      INT AUTO_INCREMENT PRIMARY KEY,
    station_code    VARCHAR(10)  NOT NULL UNIQUE,
    station_name    VARCHAR(100) NOT NULL,
    city            VARCHAR(100),
    state           VARCHAR(100)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- class  (travel classes and their fare multiplier)
-- ---------------------------------------------------------------------
CREATE TABLE class (
    class_id        INT AUTO_INCREMENT PRIMARY KEY,
    class_code      VARCHAR(10)  NOT NULL UNIQUE,   -- SL, 3A, 2A, 1A, CC
    class_name      VARCHAR(50)  NOT NULL,
    fare_multiplier DECIMAL(5,2) NOT NULL DEFAULT 1.00
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- trains
-- ---------------------------------------------------------------------
CREATE TABLE trains (
    train_id             INT AUTO_INCREMENT PRIMARY KEY,
    train_number         VARCHAR(10)  NOT NULL UNIQUE,
    train_name           VARCHAR(100) NOT NULL,
    source_station_id    INT NOT NULL,
    destination_station_id INT NOT NULL,
    departure_time       TIME NOT NULL,
    arrival_time         TIME NOT NULL,
    base_fare_per_km     DECIMAL(6,2) NOT NULL DEFAULT 1.00,
    run_days             SET('MON','TUE','WED','THU','FRI','SAT','SUN') NOT NULL,
    FOREIGN KEY (source_station_id)      REFERENCES stations(station_id),
    FOREIGN KEY (destination_station_id) REFERENCES stations(station_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- routes  (ordered stoppages of a train)
-- ---------------------------------------------------------------------
CREATE TABLE routes (
    route_id                INT AUTO_INCREMENT PRIMARY KEY,
    train_id                INT NOT NULL,
    station_id              INT NOT NULL,
    seq_no                  INT NOT NULL,
    arrival_time            TIME,
    departure_time          TIME,
    distance_from_source_km INT NOT NULL DEFAULT 0,
    FOREIGN KEY (train_id)   REFERENCES trains(train_id) ON DELETE CASCADE,
    FOREIGN KEY (station_id) REFERENCES stations(station_id),
    UNIQUE KEY uq_train_seq (train_id, seq_no)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- passengers
-- ---------------------------------------------------------------------
CREATE TABLE passengers (
    passenger_id    INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    age             INT NOT NULL,
    gender          ENUM('M','F','O') NOT NULL,
    category        ENUM('GENERAL','SENIOR_CITIZEN','LADIES','DISABLED','ARMED_FORCES')
                        NOT NULL DEFAULT 'GENERAL',
    id_proof_type   VARCHAR(30),
    id_proof_number VARCHAR(30),
    contact_number  VARCHAR(15),
    email           VARCHAR(100)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- seat  (seat inventory per train + class + travel date)
-- ---------------------------------------------------------------------
CREATE TABLE seat (
    seat_inv_id     INT AUTO_INCREMENT PRIMARY KEY,
    train_id        INT NOT NULL,
    class_id        INT NOT NULL,
    travel_date     DATE NOT NULL,
    total_seats     INT NOT NULL,
    confirmed_booked INT NOT NULL DEFAULT 0,
    rac_capacity    INT NOT NULL DEFAULT 0,
    rac_booked      INT NOT NULL DEFAULT 0,
    wl_count        INT NOT NULL DEFAULT 0,
    FOREIGN KEY (train_id) REFERENCES trains(train_id) ON DELETE CASCADE,
    FOREIGN KEY (class_id) REFERENCES class(class_id),
    UNIQUE KEY uq_seat_inventory (train_id, class_id, travel_date),
    CHECK (confirmed_booked <= total_seats),
    CHECK (rac_booked <= rac_capacity)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- ticket
-- ---------------------------------------------------------------------
CREATE TABLE ticket (
    ticket_id       INT AUTO_INCREMENT PRIMARY KEY,
    pnr_number      CHAR(10) NOT NULL UNIQUE,
    passenger_id    INT NOT NULL,
    train_id        INT NOT NULL,
    class_id        INT NOT NULL,
    travel_date     DATE NOT NULL,
    booking_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_station_id      INT NOT NULL,
    destination_station_id INT NOT NULL,
    seat_number     VARCHAR(10),
    coach_number    VARCHAR(10),
    status          ENUM('CONFIRMED','RAC','WL','CANCELLED') NOT NULL,
    fare            DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id),
    FOREIGN KEY (train_id)     REFERENCES trains(train_id),
    FOREIGN KEY (class_id)     REFERENCES class(class_id),
    FOREIGN KEY (source_station_id)      REFERENCES stations(station_id),
    FOREIGN KEY (destination_station_id) REFERENCES stations(station_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- payment
-- ---------------------------------------------------------------------
CREATE TABLE payment (
    payment_id      INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id       INT NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    payment_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_mode    ENUM('CASH','CARD','UPI','NETBANKING') NOT NULL DEFAULT 'UPI',
    payment_status  ENUM('SUCCESS','REFUNDED','PARTIALLY_REFUNDED','FAILED')
                        NOT NULL DEFAULT 'SUCCESS',
    FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- rac_info
-- ---------------------------------------------------------------------
CREATE TABLE rac_info (
    rac_id      INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id   INT NOT NULL,
    train_id    INT NOT NULL,
    class_id    INT NOT NULL,
    travel_date DATE NOT NULL,
    rac_number  INT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE,
    FOREIGN KEY (train_id)  REFERENCES trains(train_id),
    FOREIGN KEY (class_id)  REFERENCES class(class_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- wl_info
-- ---------------------------------------------------------------------
CREATE TABLE wl_info (
    wl_id       INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id   INT NOT NULL,
    train_id    INT NOT NULL,
    class_id    INT NOT NULL,
    travel_date DATE NOT NULL,
    wl_number   INT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id) ON DELETE CASCADE,
    FOREIGN KEY (train_id)  REFERENCES trains(train_id),
    FOREIGN KEY (class_id)  REFERENCES class(class_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- refund_record
-- ---------------------------------------------------------------------
CREATE TABLE refund_record (
    refund_id           INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id           INT NOT NULL,
    original_fare       DECIMAL(10,2) NOT NULL,
    cancellation_charge DECIMAL(10,2) NOT NULL,
    refund_amount       DECIMAL(10,2) NOT NULL,
    refund_date         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES ticket(ticket_id)
) ENGINE=InnoDB;

-- helpful indexes
CREATE INDEX idx_ticket_train_date ON ticket(train_id, travel_date);
CREATE INDEX idx_ticket_status     ON ticket(status);
CREATE INDEX idx_rac_lookup        ON rac_info(train_id, class_id, travel_date, rac_number);
CREATE INDEX idx_wl_lookup         ON wl_info(train_id, class_id, travel_date, wl_number);


-- =====================================================================
-- 2. SAMPLE (SEED) DATA
-- =====================================================================

INSERT INTO stations (station_code, station_name, city, state) VALUES
('NDLS', 'New Delhi',        'Delhi',      'Delhi'),
('BCT',  'Mumbai Central',   'Mumbai',     'Maharashtra'),
('MAS',  'Chennai Central',  'Chennai',    'Tamil Nadu'),
('HWH',  'Howrah Junction',  'Kolkata',    'West Bengal'),
('PNBE', 'Patna Junction',   'Patna',      'Bihar');

INSERT INTO class (class_code, class_name, fare_multiplier) VALUES
('SL', 'Sleeper Class',     1.00),
('3A', 'AC 3 Tier',         2.50),
('2A', 'AC 2 Tier',         3.50),
('1A', 'AC First Class',    5.00),
('CC', 'AC Chair Car',      2.00);

INSERT INTO trains (train_number, train_name, source_station_id, destination_station_id,
                     departure_time, arrival_time, base_fare_per_km, run_days) VALUES
('12301', 'Howrah Rajdhani',        1, 4, '16:50:00', '10:05:00', 1.20, 'MON,TUE,WED,THU,FRI,SAT,SUN'),
('12951', 'Mumbai Rajdhani',        1, 2, '16:25:00', '08:35:00', 1.30, 'MON,WED,FRI,SUN'),
('12621', 'Tamil Nadu Express',     1, 3, '22:30:00', '07:15:00', 1.00, 'MON,TUE,WED,THU,FRI,SAT,SUN'),
('12309', 'Rajendranagar Rajdhani', 1, 5, '20:00:00', '06:30:00', 1.15, 'TUE,THU,SAT');

-- routes: distance_from_source_km is cumulative distance from the train's origin
INSERT INTO routes (train_id, station_id, seq_no, arrival_time, departure_time, distance_from_source_km) VALUES
-- 12301 New Delhi -> Patna -> Howrah
(1, 1, 1, NULL,      '16:50:00', 0),
(1, 5, 2, '22:40:00','22:45:00', 990),
(1, 4, 3, '10:05:00', NULL,      1450),
-- 12951 New Delhi -> Mumbai
(2, 1, 1, NULL,      '16:25:00', 0),
(2, 2, 2, '08:35:00', NULL,      1385),
-- 12621 New Delhi -> Chennai
(3, 1, 1, NULL,      '22:30:00', 0),
(3, 3, 2, '07:15:00', NULL,      2180),
-- 12309 New Delhi -> Patna
(4, 1, 1, NULL,      '20:00:00', 0),
(4, 5, 2, '06:30:00', NULL,      990);

-- seat inventory for a couple of travel dates so the procedures can be tested
INSERT INTO seat (train_id, class_id, travel_date, total_seats, confirmed_booked, rac_capacity, rac_booked, wl_count) VALUES
(1, 1, '2026-09-10', 5, 0, 2, 0, 0),  -- train 12301, Sleeper
(1, 2, '2026-09-10', 3, 0, 2, 0, 0),  -- train 12301, 3A
(3, 1, '2026-09-12', 4, 0, 2, 0, 0),  -- train 12621, Sleeper
(4, 2, '2026-09-15', 3, 0, 1, 0, 0);  -- train 12309, 3A


-- =====================================================================
-- 3. STORED PROCEDURES
-- =====================================================================

DELIMITER $$

-- ---------------------------------------------------------------------
-- book_tickets
--   Books ONE passenger per call. To book a group of passengers under
--   the same PNR, call this once with p_pnr = NULL (it will generate a
--   PNR and return it), then call it again for each remaining passenger
--   passing the SAME p_pnr back in.
-- ---------------------------------------------------------------------
CREATE PROCEDURE book_tickets (
    IN  p_name               VARCHAR(100),
    IN  p_age                INT,
    IN  p_gender             ENUM('M','F','O'),
    IN  p_category           ENUM('GENERAL','SENIOR_CITIZEN','LADIES','DISABLED','ARMED_FORCES'),
    IN  p_train_id           INT,
    IN  p_class_id           INT,
    IN  p_travel_date        DATE,
    IN  p_source_station_id  INT,
    IN  p_dest_station_id    INT,
    INOUT p_pnr              CHAR(10),
    OUT p_status             VARCHAR(20),
    OUT p_ticket_id          INT
)
proc_body: BEGIN
    DECLARE v_passenger_id   INT;
    DECLARE v_total_seats    INT;
    DECLARE v_confirmed      INT;
    DECLARE v_rac_cap        INT;
    DECLARE v_rac_booked     INT;
    DECLARE v_wl_count       INT;
    DECLARE v_src_dist       INT DEFAULT NULL;
    DECLARE v_dst_dist       INT DEFAULT NULL;
    DECLARE v_distance       INT;
    DECLARE v_base_fare      DECIMAL(6,2);
    DECLARE v_fare_mult      DECIMAL(5,2);
    DECLARE v_fare           DECIMAL(10,2);
    DECLARE v_seat_number    VARCHAR(10);
    DECLARE v_new_rac_no     INT;
    DECLARE v_new_wl_no      INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- lock the seat-inventory row for this train/class/date
    SELECT total_seats, confirmed_booked, rac_capacity, rac_booked, wl_count
      INTO v_total_seats, v_confirmed, v_rac_cap, v_rac_booked, v_wl_count
    FROM seat
    WHERE train_id = p_train_id AND class_id = p_class_id AND travel_date = p_travel_date
    FOR UPDATE;

    IF v_total_seats IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No seat inventory configured for this train/class/date';
    END IF;

    -- distance / fare calculation
    SELECT distance_from_source_km INTO v_src_dist
    FROM routes WHERE train_id = p_train_id AND station_id = p_source_station_id;

    SELECT distance_from_source_km INTO v_dst_dist
    FROM routes WHERE train_id = p_train_id AND station_id = p_dest_station_id;

    IF v_src_dist IS NULL OR v_dst_dist IS NULL OR v_dst_dist <= v_src_dist THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid source/destination for this train route';
    END IF;

    SET v_distance = v_dst_dist - v_src_dist;

    SELECT base_fare_per_km INTO v_base_fare FROM trains WHERE train_id = p_train_id;
    SELECT fare_multiplier  INTO v_fare_mult FROM class  WHERE class_id = p_class_id;

    SET v_fare = v_distance * v_base_fare * v_fare_mult;

    IF p_category = 'SENIOR_CITIZEN' THEN
        SET v_fare = v_fare * 0.60;   -- example 40% concession
    END IF;

    -- create passenger record
    INSERT INTO passengers (name, age, gender, category)
    VALUES (p_name, p_age, p_gender, p_category);
    SET v_passenger_id = LAST_INSERT_ID();

    -- reuse or generate PNR
    IF p_pnr IS NULL OR p_pnr = '' THEN
        SET p_pnr = CONCAT('PNR', LPAD(FLOOR(RAND() * 10000000), 7, '0'));
    END IF;

    -- allocate: CONFIRMED -> RAC -> WL
    IF v_confirmed < v_total_seats THEN
        SET p_status = 'CONFIRMED';
        SET v_seat_number = CONCAT('S', v_confirmed + 1);
        UPDATE seat SET confirmed_booked = confirmed_booked + 1
          WHERE train_id = p_train_id AND class_id = p_class_id AND travel_date = p_travel_date;

    ELSEIF v_rac_booked < v_rac_cap THEN
        SET p_status = 'RAC';
        SET v_new_rac_no = v_rac_booked + 1;
        UPDATE seat SET rac_booked = rac_booked + 1
          WHERE train_id = p_train_id AND class_id = p_class_id AND travel_date = p_travel_date;

    ELSE
        SET p_status = 'WL';
        SET v_new_wl_no = v_wl_count + 1;
        UPDATE seat SET wl_count = wl_count + 1
          WHERE train_id = p_train_id AND class_id = p_class_id AND travel_date = p_travel_date;
    END IF;

    INSERT INTO ticket (pnr_number, passenger_id, train_id, class_id, travel_date,
                         source_station_id, destination_station_id,
                         seat_number, coach_number, status, fare)
    VALUES (p_pnr, v_passenger_id, p_train_id, p_class_id, p_travel_date,
            p_source_station_id, p_dest_station_id,
            IF(p_status = 'CONFIRMED', v_seat_number, NULL),
            IF(p_status = 'CONFIRMED', 'C1', NULL),
            p_status, v_fare);

    SET p_ticket_id = LAST_INSERT_ID();

    IF p_status = 'RAC' THEN
        INSERT INTO rac_info (ticket_id, train_id, class_id, travel_date, rac_number)
        VALUES (p_ticket_id, p_train_id, p_class_id, p_travel_date, v_new_rac_no);
    ELSEIF p_status = 'WL' THEN
        INSERT INTO wl_info (ticket_id, train_id, class_id, travel_date, wl_number)
        VALUES (p_ticket_id, p_train_id, p_class_id, p_travel_date, v_new_wl_no);
    END IF;

    INSERT INTO payment (ticket_id, amount, payment_mode, payment_status)
    VALUES (p_ticket_id, v_fare, 'UPI', 'SUCCESS');

    COMMIT;
END proc_body $$


-- ---------------------------------------------------------------------
-- cancel_ticket
--   Cancels a ticket, records a refund (minus a status-based cancellation
--   charge), frees the seat/RAC/WL slot and promotes the queue:
--   CONFIRMED cancelled -> first RAC promoted to CONFIRMED
--                        -> first WL   promoted to RAC
--   RAC cancelled        -> first WL   promoted to RAC
-- ---------------------------------------------------------------------
CREATE PROCEDURE cancel_ticket (
    IN p_ticket_id INT
)
proc_body: BEGIN
    DECLARE v_status      ENUM('CONFIRMED','RAC','WL','CANCELLED');
    DECLARE v_train_id    INT;
    DECLARE v_class_id    INT;
    DECLARE v_travel_date DATE;
    DECLARE v_fare        DECIMAL(10,2);
    DECLARE v_cancel_charge DECIMAL(10,2);
    DECLARE v_refund      DECIMAL(10,2);
    DECLARE v_promote_rac_ticket INT DEFAULT NULL;
    DECLARE v_promote_wl_ticket  INT DEFAULT NULL;
    DECLARE v_next_seat_no INT;
    DECLARE v_next_rac_no  INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT status, train_id, class_id, travel_date, fare
      INTO v_status, v_train_id, v_class_id, v_travel_date, v_fare
    FROM ticket
    WHERE ticket_id = p_ticket_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket not found';
    END IF;

    IF v_status = 'CANCELLED' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket is already cancelled';
    END IF;

    -- simple flat-rate cancellation charge by current status
    CASE v_status
        WHEN 'CONFIRMED' THEN SET v_cancel_charge = v_fare * 0.10;
        WHEN 'RAC'       THEN SET v_cancel_charge = v_fare * 0.05;
        WHEN 'WL'        THEN SET v_cancel_charge = v_fare * 0.03;
    END CASE;
    SET v_refund = v_fare - v_cancel_charge;

    UPDATE ticket SET status = 'CANCELLED' WHERE ticket_id = p_ticket_id;

    INSERT INTO refund_record (ticket_id, original_fare, cancellation_charge, refund_amount)
    VALUES (p_ticket_id, v_fare, v_cancel_charge, v_refund);

    UPDATE payment SET payment_status = 'REFUNDED' WHERE ticket_id = p_ticket_id;

    IF v_status = 'CONFIRMED' THEN
        UPDATE seat SET confirmed_booked = confirmed_booked - 1
          WHERE train_id = v_train_id AND class_id = v_class_id AND travel_date = v_travel_date;

        -- promote earliest RAC passenger to CONFIRMED
        SELECT t.ticket_id INTO v_promote_rac_ticket
        FROM rac_info r JOIN ticket t ON r.ticket_id = t.ticket_id
        WHERE r.train_id = v_train_id AND r.class_id = v_class_id AND r.travel_date = v_travel_date
          AND t.status = 'RAC'
        ORDER BY r.rac_number ASC LIMIT 1;

        IF v_promote_rac_ticket IS NOT NULL THEN
            SELECT confirmed_booked + 1 INTO v_next_seat_no
            FROM seat WHERE train_id = v_train_id AND class_id = v_class_id AND travel_date = v_travel_date;

            UPDATE ticket
               SET status = 'CONFIRMED', seat_number = CONCAT('S', v_next_seat_no), coach_number = 'C1'
             WHERE ticket_id = v_promote_rac_ticket;

            UPDATE seat SET confirmed_booked = confirmed_booked + 1, rac_booked = rac_booked - 1
              WHERE train_id = v_train_id AND class_id = v_class_id AND travel_date = v_travel_date;

            DELETE FROM rac_info WHERE ticket_id = v_promote_rac_ticket;

            -- cascade: promote earliest WL passenger into the now-empty RAC slot
            SELECT t.ticket_id INTO v_promote_wl_ticket
            FROM wl_info w JOIN ticket t ON w.ticket_id = t.ticket_id
            WHERE w.train_id = v_train_id AND w.class_id = v_class_id AND w.travel_date = v_travel_date
              AND t.status = 'WL'
            ORDER BY w.wl_number ASC LIMIT 1;

            IF v_promote_wl_ticket IS NOT NULL THEN
                SELECT rac_booked + 1 INTO v_next_rac_no
                FROM seat WHERE train_id = v_train_id AND class_id = v_class_id AND travel_date = v_travel_date;

                UPDATE ticket SET status = 'RAC' WHERE ticket_id = v_promote_wl_ticket;

                INSERT INTO rac_info (ticket_id, train_id, class_id, travel_date, rac_number)
                VALUES (v_promote_wl_ticket, v_train_id, v_class_id, v_travel_date, v_next_rac_no);

                UPDATE seat SET rac_booked = rac_booked + 1, wl_count = wl_count - 1
                  WHERE train_id = v_train_id AND class_id = v_class_id AND travel_date = v_travel_date;

                DELETE FROM wl_info WHERE ticket_id = v_promote_wl_ticket;
            END IF;
        END IF;

    ELSEIF v_status = 'RAC' THEN
        UPDATE seat SET rac_booked = rac_booked - 1
          WHERE train_id = v_train_id AND class_id = v_class_id AND travel_date = v_travel_date;
        DELETE FROM rac_info WHERE ticket_id = p_ticket_id;

        -- promote earliest WL passenger to RAC
        SELECT t.ticket_id INTO v_promote_wl_ticket
        FROM wl_info w JOIN ticket t ON w.ticket_id = t.ticket_id
        WHERE w.train_id = v_train_id AND w.class_id = v_class_id AND w.travel_date = v_travel_date
          AND t.status = 'WL'
        ORDER BY w.wl_number ASC LIMIT 1;

        IF v_promote_wl_ticket IS NOT NULL THEN
            SELECT rac_booked + 1 INTO v_next_rac_no
            FROM seat WHERE train_id = v_train_id AND class_id = v_class_id AND travel_date = v_travel_date;

            UPDATE ticket SET status = 'RAC' WHERE ticket_id = v_promote_wl_ticket;

            INSERT INTO rac_info (ticket_id, train_id, class_id, travel_date, rac_number)
            VALUES (v_promote_wl_ticket, v_train_id, v_class_id, v_travel_date, v_next_rac_no);

            UPDATE seat SET rac_booked = rac_booked + 1, wl_count = wl_count - 1
              WHERE train_id = v_train_id AND class_id = v_class_id AND travel_date = v_travel_date;

            DELETE FROM wl_info WHERE ticket_id = v_promote_wl_ticket;
        END IF;

    ELSEIF v_status = 'WL' THEN
        UPDATE seat SET wl_count = wl_count - 1
          WHERE train_id = v_train_id AND class_id = v_class_id AND travel_date = v_travel_date;
        DELETE FROM wl_info WHERE ticket_id = p_ticket_id;
    END IF;

    COMMIT;
END proc_body $$


-- ---------------------------------------------------------------------
-- get_trains_by_date
--   Returns every train that runs on the given calendar date
--   (matched against the train's run_days set).
-- ---------------------------------------------------------------------
CREATE PROCEDURE get_trains_by_date (
    IN p_date DATE
)
BEGIN
    DECLARE v_day VARCHAR(3);
    SET v_day = UPPER(LEFT(DAYNAME(p_date), 3));

    SELECT t.train_id, t.train_number, t.train_name,
           s1.station_name AS source_station,
           s2.station_name AS destination_station,
           t.departure_time, t.arrival_time, t.run_days
    FROM trains t
    JOIN stations s1 ON t.source_station_id = s1.station_id
    JOIN stations s2 ON t.destination_station_id = s2.station_id
    WHERE FIND_IN_SET(v_day, t.run_days) > 0
    ORDER BY t.departure_time;
END $$


-- ---------------------------------------------------------------------
-- CheckPNRStatus
--   Shows full ticket/status detail for a given PNR.
-- ---------------------------------------------------------------------
CREATE PROCEDURE CheckPNRStatus (
    IN p_pnr CHAR(10)
)
BEGIN
    SELECT tk.pnr_number,
           p.name, p.age, p.gender, p.category,
           tr.train_number, tr.train_name,
           c.class_name,
           tk.travel_date,
           s1.station_name AS from_station,
           s2.station_name AS to_station,
           tk.status,
           tk.seat_number, tk.coach_number,
           tk.fare,
           r.rac_number,
           w.wl_number,
           tk.booking_date
    FROM ticket tk
    JOIN passengers p ON tk.passenger_id = p.passenger_id
    JOIN trains tr    ON tk.train_id = tr.train_id
    JOIN class c      ON tk.class_id = c.class_id
    JOIN stations s1  ON tk.source_station_id = s1.station_id
    JOIN stations s2  ON tk.destination_station_id = s2.station_id
    LEFT JOIN rac_info r ON tk.ticket_id = r.ticket_id
    LEFT JOIN wl_info  w ON tk.ticket_id = w.ticket_id
    WHERE tk.pnr_number = p_pnr;
END $$


-- ---------------------------------------------------------------------
-- GetAvailableSeats
--   Shows seat availability for a train/class/date.
-- ---------------------------------------------------------------------
CREATE PROCEDURE GetAvailableSeats (
    IN p_train_id    INT,
    IN p_class_id    INT,
    IN p_travel_date DATE
)
BEGIN
    SELECT tr.train_number, tr.train_name, c.class_name, sv.travel_date,
           sv.total_seats,
           sv.confirmed_booked,
           (sv.total_seats - sv.confirmed_booked)      AS confirmed_available,
           sv.rac_capacity,
           sv.rac_booked,
           (sv.rac_capacity - sv.rac_booked)            AS rac_available,
           sv.wl_count                                  AS current_waitlist_length
    FROM seat sv
    JOIN trains tr ON sv.train_id = tr.train_id
    JOIN class c   ON sv.class_id = c.class_id
    WHERE sv.train_id = p_train_id
      AND sv.class_id = p_class_id
      AND sv.travel_date = p_travel_date;
END $$


-- ---------------------------------------------------------------------
-- GetPassengerList
--   Lists all (non-cancelled) passengers booked on a train for a date.
-- ---------------------------------------------------------------------
CREATE PROCEDURE GetPassengerList (
    IN p_train_id    INT,
    IN p_travel_date DATE
)
BEGIN
    SELECT tk.pnr_number, p.name, p.age, p.gender, p.category,
           c.class_name, tk.seat_number, tk.coach_number, tk.status
    FROM ticket tk
    JOIN passengers p ON tk.passenger_id = p.passenger_id
    JOIN class c      ON tk.class_id = c.class_id
    WHERE tk.train_id = p_train_id
      AND tk.travel_date = p_travel_date
      AND tk.status <> 'CANCELLED'
    ORDER BY c.class_name, tk.status, tk.seat_number;
END $$


-- ---------------------------------------------------------------------
-- Bonus: GetRevenueReport / GetRefundReport
--   Simple analytics procedures matching the "revenue and refund
--   reports" feature described in the project overview.
-- ---------------------------------------------------------------------
CREATE PROCEDURE GetRevenueReport (
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    SELECT tr.train_number, tr.train_name,
           COUNT(tk.ticket_id)                              AS tickets_booked,
           SUM(tk.fare)                                      AS gross_fare_collected,
           SUM(CASE WHEN tk.status = 'CANCELLED' THEN 1 ELSE 0 END) AS tickets_cancelled
    FROM ticket tk
    JOIN trains tr ON tk.train_id = tr.train_id
    WHERE tk.travel_date BETWEEN p_start_date AND p_end_date
    GROUP BY tr.train_id, tr.train_number, tr.train_name
    ORDER BY gross_fare_collected DESC;
END $$

CREATE PROCEDURE GetRefundReport (
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    SELECT rr.refund_id, tk.pnr_number, p.name AS passenger_name,
           tr.train_number, rr.original_fare, rr.cancellation_charge,
           rr.refund_amount, rr.refund_date
    FROM refund_record rr
    JOIN ticket tk       ON rr.ticket_id = tk.ticket_id
    JOIN passengers p    ON tk.passenger_id = p.passenger_id
    JOIN trains tr       ON tk.train_id = tr.train_id
    WHERE DATE(rr.refund_date) BETWEEN p_start_date AND p_end_date
    ORDER BY rr.refund_date DESC;
END $$

DELIMITER ;





