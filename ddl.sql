/*

Overnight Room
Meeting Room - the enum types Saro suggested
Reservation 
Food_Order - multiple orders (one per day I guess)
Feedback
Payment / Billing
*/

drop if exists user_authentication;
drop if exists user;

drop if exists employee_details;
drop if exists employee;

drop if exists hotel;

create table user (
    user_id serial primary key,
    first_name varchar(50) not null,
    middle_name varchar(50),
    last_name varchar(50) not null,
    email varchar(100) unique not null,
    phone_number varchar(20) unique,
    created_at datetime
);

 -- the same table cannot be used for both users and employees. maybe we should ask Saro whether having this as a separate table for clarity is a good idea
create table user_authentication (
    user_id int primary key references user(user_id),
    password_hash text not null,
    password_last_updated datetime not null,
    totp_secret text,
    security_question text,
    security_question_hash text
);

drop type if exists employee_role as enum('branch_manager', 'cleaner', 'support_agent', 'front_desk_agent', 'lobby_attendant', 'security_guard');

create table employee (
    employee_id serial primary key,
    first_name varchar(50) not null,
    middle_name varchar(50),
    last_name varchar(50) not null,
    email varchar(100) unique not null,
    phone_number varchar(20) unique,
    role employee_role not null
);

create table employee_details (
    employee_id int primary key references employee(employee_id),
    contract_start date not null,
    supervisor_id int references employee(employee_id),
    salary decimal(10, 2), not null,
    salary_transaction_account text,
    hotel_id references hotel(hotel_id)
);


drop type if exists address;

create type address as (
    street text,
    city varchar(255),
    country varchar(255)
);


create table hotel ( -- same as hotel I guess
    hotel_id serial primary key,
    name varchar(100) not null unique,
    hotel_address address,
    room_quantity int not null,
    capacity int not null,
    branch_manager_id int references employee(employee_details)
);

