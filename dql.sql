--BASIC OPERATIONS

--Registering a New Guest
INSERT INTO "user" (first_name, middle_name, last_name, email, phone_number, created_at)
VALUES ('Ann', 'Maggie', 'Doe', 'ann.doe@gmail.com', '091123456', NOW());

--Leaving Feedback After a Completed Stay
INSERT INTO feedback (reservation_id, feedback_response, rating, created_at)
VALUES (51, 'Everything was excellent!', 5, '2024-08-15 14:30:00');

--Placing a Food Order During a Stay
INSERT INTO food_order (reservation_id, amount, created_at) VALUES (51, 59.99, '2024-08-15 13:15:00');

-- Room popularity by branch(Most and Least Booked Overnight Rooms)
WITH room_bookings AS (
    SELECT 
        h.name AS hotel_name,
        o.room_number,
        COUNT(overnight_room_reservation.reservation_id) AS times_booked
    FROM 
        overnight_room o
    LEFT JOIN overnight_room_reservation 
        ON o.room_id = overnight_room_reservation.room_id
    JOIN hotel h 
        ON o.hotel_id = h.hotel_id
    GROUP BY 
        h.name, o.room_number, o.room_id
)
SELECT * 
FROM room_bookings
WHERE times_booked = (SELECT MAX(times_booked) FROM room_bookings)
   OR times_booked = (SELECT MIN(times_booked) FROM room_bookings)
ORDER BY times_booked DESC;

--Most and Least Booked Meeting Rooms
WITH meeting_bookings AS (
    SELECT 
        h.name AS hotel_name,
        m.room_number,
        COUNT(meeting_room_reservation.reservation_id) AS times_booked
    FROM 
        meeting_room m
    LEFT JOIN meeting_room_reservation 
        ON m.room_id = meeting_room_reservation.room_id
    JOIN hotel h 
        ON m.hotel_id = h.hotel_id
    GROUP BY 
        h.name, m.room_number, m.room_id
)
SELECT * 
FROM meeting_bookings
WHERE times_booked = (SELECT MAX(times_booked) FROM meeting_bookings)
   OR times_booked = (SELECT MIN(times_booked) FROM meeting_bookings)
ORDER BY times_booked DESC;

-- Generate a bill for a guest’s food consumption.

SELECT 
    fo.reservation_id,
    SUM(fo.amount) AS total_food_bill
FROM 
    food_order fo
GROUP BY 
    fo.reservation_id
ORDER BY 
    total_food_bill DESC;


Գոռ կարաս դու քոնի հետ դրանք էլ DQL ավելացնես ու նոր pushանե՞ս

--Visitor-Focused Queries

-- 1. View stay history, payments, and feedback

SELECT 
    r.reservation_id,
    r.check_in_date,
    r.check_out_date,
    r.total_cost,
    p.amount AS payment_amount,
    f.feedback_response,
    f.rating
FROM 
    reservation r
LEFT JOIN payment p ON r.reservation_id = p.reservation_id
LEFT JOIN feedback f ON r.reservation_id = f.reservation_id
WHERE 
    r.user_id = 1;


--2 Check available rooms in a city and date range

SELECT 
    o.room_id,
    o.room_number,
    o.price_per_night,
    h.name AS hotel_name,
    (h.hotel_address).city AS city
FROM 
    overnight_room o
JOIN hotel h ON o.hotel_id = h.hotel_id
WHERE 
    (h.hotel_address).city = 'Dilijan'
    AND o.room_id NOT IN (
        SELECT orr.room_id
        FROM overnight_room_reservation orr
        JOIN reservation r ON orr.reservation_id = r.reservation_id
        WHERE 
            r.check_in_date <= '2024-08-10'
            AND 
            r.check_out_date >= '2024-08-01'
    );


-- 3. What food orders did the user make during their last stay?

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    fo.order_id,
    fo.order_details,
    fo.amount
FROM "user" u
JOIN reservation r on u.user_id = r.user_id
JOIN food_order fo on r.reservation_id = fo.reservation_id
WHERE r.check_in_date = (
    SELECT MAX(r2.check_in_date)
    FROM reservation r2
    WHERE r2.user_id = u.user_id
)
ORDER BY u.user_id, fo.order_id;

-- 4. What rooms are currently occupied or reserved today?

SELECT DISTINCT orr.room_id, ovr.room_number, 'overnight' AS room_category
FROM overnight_room_reservation orr
JOIN reservation r ON orr.reservation_id = r.reservation_id
JOIN overnight_room ovr ON orr.room_id = ovr.room_id
WHERE current_date BETWEEN r.check_in_date::date AND r.check_out_date::date

UNION

SELECT DISTINCT mrr.room_id, mr.room_number, 'meeting' AS room_category
FROM meeting_room_reservation mrr
JOIN reservation r ON mrr.reservation_id = r.reservation_id
JOIN meeting_room mr ON mrr.room_id = mr.room_id
WHERE current_date BETWEEN r.check_in_date::date AND r.check_out_date::date;

-- 5. Get all active room service food orders.

SELECT fo.*
FROM food_order fo
JOIN reservation r ON fo.reservation_id = r.reservation_id
WHERE current_date BETWEEN r.check_in_date::date AND r.check_out_date::date;

-- 6. Show top 5 most ordered food items this month.
SELECT order_details, COUNT(*) AS times_ordered
FROM food_order
WHERE date_trunc('month', created_at) = date_trunc('month', now())
GROUP BY order_details
ORDER BY times_ordered DESC
limit 5;

-- 8. List all rooms in a branch and their availability.

SELECT 
    ovr.room_number, 
    ovr.hotel_id,
    h.name AS hotel_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM overnight_room_reservation orr
            JOIN reservation r ON orr.reservation_id = r.reservation_id
            WHERE orr.room_id = ovr.room_id
              AND CURRENT_DATE BETWEEN r.check_in_date::date AND r.check_out_date::date
              AND r.status = 'reserved'
        ) THEN 'RESERVED'
        ELSE 'AVAILABLE'
    END AS status
FROM 
    overnight_room ovr
JOIN 
    hotel h ON ovr.hotel_id = h.hotel_id
WHERE 
    h.hotel_id IN (1, 2, 3, 4, 5)
ORDER BY 
    h.hotel_id;

-- 9. Get a reservation’s full details, including user and payment info

SELECT r.*, u.first_name, u.last_name, u.email, p.amount as payment_amount, p.payment_method
FROM reservation r
JOIN "user" u ON r.user_id = u.user_id
LEFT JOIN payment p ON r.reservation_id = p.reservation_id
LIMIT 5;

-- 10. View all reservations for a specific date range.
SELECT *
FROM reservation
WHERE check_in_date::date BETWEEN '2024-01-01'::date AND '2024-01-31'::date
OR check_out_date::date BETWEEN '2024-06-01'::date AND '2024-07-31'::date;


-- 11. Show all reservations made for a branch within a given time period
SELECT r.*
FROM reservation r
JOIN overnight_room_reservation orr ON r.reservation_id = orr.reservation_id
JOIN overnight_room ovr ON orr.room_id = ovr.room_id
WHERE ovr.hotel_id IN (1, 2, 3, 4, 5)
  AND (r. check_in_date::date BETWEEN '2024-01-01'::date AND '2024-01-31'::date
OR r.check_out_date::date BETWEEN '2024-06-01'::date AND '2024-07-31'::date);

-- 12. Show all employees and their assigned branches

SELECT e.user_id, u.first_name, u.last_name, e.role, h.name AS hotel_name
FROM employee_details e
JOIN "user" u ON e.user_id = u.user_id
JOIN hotel h ON e.hotel_id = h.hotel_id;

-- 13. Monthly revenue report (rooms and food)

SELECT
    date_trunc('month', p.created_at) AS month,
    'room' AS service_type,
    SUM(p.amount) AS total_amount
FROM payment p
GROUP BY month

UNION ALL

SELECT
    date_trunc('month', fo.created_at) AS month,
    'food' AS service_type,
    SUM(fo.amount) AS total_amount
FROM food_order fo
GROUP BY month
ORDER BY month;

-- 14. Revenue by room type per month (last year)

SELECT
    date_trunc('month', r.created_at) AS month,
    ovr.room_type,
    SUM(r.total_cost) AS total_revenue
FROM reservation r
JOIN overnight_room_reservation orr ON r.reservation_id = orr.reservation_id
JOIN overnight_room ovr ON orr.room_id = ovr.room_id
WHERE r.created_at >= date_trunc('year', now()) - interval '1 year'
GROUP BY month, ovr.room_type
order by month, ovr.room_type;
