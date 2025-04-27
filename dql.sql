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


