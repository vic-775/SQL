-- seeting int singke user model
alter database Lib_DB set single_user with rollback immediate;
drop database Lib_DB;

-- creating database Lib_Db
create database Lib_Db;

-- books table 
use Lib_Db;
select * from [books];
alter table books alter column isbn varchar(100) not null;
alter table books add constraint pk_books primary key (isbn);

-- branch table
select * from [branch];
alter table branch alter column branch_id varchar(100) not null;
alter table branch add constraint pk_branch primary key (branch_id);

-- employees table
select * from [employees];
alter table employees alter column emp_id varchar(100) not null;
alter table employees add constraint pk_employees primary key (emp_id);

-- issued_status table
select * from [issued_status];
alter table issued_status alter column issued_id varchar(100) not null;
alter table issued_status add constraint pk_issued_status primary key (issued_id);

-- members table
select * from [members];
alter table members alter column member_id varchar(100) not null;
alter table members add constraint pk_members primary key (member_id);

-- return_status
select * from [return_status];
alter table return_status alter column return_id varchar(100) not null;
alter table return_status add constraint pk_return_status primary key (return_id);

-- creating relationships between the tables
-- 1. branch and employees
select * from branch; select * from employees;
alter table employees alter column branch_id varchar(100) not null;
alter table employees add constraint fk_branch_em foreign key (branch_id) references branch(branch_id);

-- 2. issued_books
select * from issued_status; select * from books;
alter table issued_status alter column issued_book_isbn varchar(100) not null;
alter table issued_status add constraint fk_issued_books foreign key (issued_book_isbn) references books(isbn);

-- 3. issued_return
select * from issued_status; select * from return_status;
alter table return_status alter column issued_id varchar(100) not null;
alter table return_status add constraint fk_issued_return foreign key (issued_id) references issued_status(issued_id);
select return_book_name from return_status where return_book_name is not null;

-- 4.issued status and members
select * from issued_status; select * from members;
alter table issued_status alter column issued_member_id varchar(100) not null;
alter table issued_status add constraint fk_issued_members foreign key (issued_member_id) references members(member_id);

-- 5.issued status and employees
select * from issued_status; select * from employees;
alter table issued_status alter column issued_emp_id varchar(100) not null;
alter table issued_status add constraint fk_issued_employees foreign key (issued_emp_id) references employees(emp_id);

-- Task 1. Create a New Book Record
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
use Lib_Db
select * from [books];
alter table [books] alter column rental_price decimal(10,2) null;
select rental_price from books; 
alter table books add rental_prices decimal (10,2) null;
UPDATE [books]
SET rental_prices = 
    DATEPART(HOUR, rental_price) + 
    (DATEPART(MINUTE, rental_price));
alter table books drop column rental_price;

insert into books (isbn, book_title, category, status, author, publisher,  rental_prices)
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 1, 'Harper Lee', 'J.B. Lippincott & Co.', 6.00);
select * from books where book_title = 'To Kill a Mockingbird'; 

-- Task 2: Update an Existing Member's Address
select * from members;

-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS104' from the issued_status table.
select * from issued_status;
delete from issued_status where issued_id = 'IS104';

-- Task 4: Retrieve All Books Issued by a Specific Employee
select * from issued_status where issued_emp_id = '101';
select * from employees where emp_id = '101.00';

-- Task 5: List Members Who Have Issued More Than One Book
-- Select * from issued_status; Select * from employees;
SELECT e.emp_name, e.emp_id, COUNT(issued_id) as [Number of books issued] FROM issued_status AS iss 
JOIN employees AS e ON iss.issued_emp_id = e.emp_id
GROUP BY e.emp_name, e.emp_id HAVING COUNT(issued_id) > 1 ORDER BY COUNT(issued_id) DESC;

-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt
CREATE TABLE book_counts (
    isbn VARCHAR(100),        
    book_title VARCHAR(100),  
    [No of times issued] INT   
);
INSERT INTO book_counts (isbn, book_title, [No of times issued])
select 
b.isbn, b.book_title, count(iss.issued_id) as [No of times issued] from books as b
join issued_status as iss on b.isbn = iss.issued_book_isbn group by b.isbn, b.book_title;

SELECT * FROM book_counts;

-- DATA ANALYSIS AND FINDINGS
-- Task 7. **Retrieve All Books in a Specific Category:
SELECT * FROM books;
SELECT distinct category FROM books;
SELECT book_title from books where category = 'Children';
SELECT book_title from books where category = 'Classic';
SELECT book_title from books where category = 'History';
SELECT book_title from books where category = 'Fiction';
SELECT book_title from books where category = 'Horror';

-- Task 8: Find Total Rental Income by Category:
SELECT category AS [Book Category], FORMAT (SUM(rental_prices), 'N2') AS [Total_Amount] FROM books
GROUP BY category ORDER BY SUM(rental_prices) DESC;

-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:
SELECT * FROM employees; SELECT * FROM branch;
SELECT e.emp_name, e.branch_id, B.manager_id FROM employees AS e JOIN branch AS b ON e.branch_id = b.branch_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold
CREATE TABLE [Books Price] (book_title VARCHAR(100), Rental_Price VARCHAR(100))
INSERT INTO [Books Price]
SELECT book_title, rental_prices AS [Rental Price] FROM books;

SELECT * FROM [Books Price];

-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT * FROM issued_status; SELECT * FROM return_status;
SELECT issued_book_name FROM issued_status AS iss LEFT JOIN return_status AS reiss ON iss.issued_id = reiss.issued_id WHERE return_id IS NULL;

-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books (assume a 60-day return period). Display the member's name, book title, issue date, and days overdue.
use Lib_Db
select * from members; select * from books; select * from issued_status; select * from return_status;

-- members who have not yet returned thier books
SELECT mem.member_id, mem.member_name, b.book_title, iss.issued_date, FORMAT(iss.issued_date, 'MMMM') AS [Issued Month],
DATEDIFF(DAY, iss.issued_date, GETDATE()) AS [Days Overdue] FROM books AS b 
JOIN issued_status AS iss ON b.isbn = iss.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = iss.issued_id
JOIN members AS mem ON iss.issued_member_id = mem.member_id
WHERE DATEDIFF(DAY, iss.issued_date, GETDATE()) > 30 AND rs.return_date IS NULL ORDER BY 1;

-- count of books not yet returned by each member name
SELECT mem.member_id, mem.member_name, COUNT(b.book_title) AS [Book Counts] FROM books AS b 
JOIN issued_status AS iss ON b.isbn = iss.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = iss.issued_id
JOIN members AS mem ON iss.issued_member_id = mem.member_id
WHERE DATEDIFF(DAY, iss.issued_date, GETDATE()) > 30 AND rs.return_date IS NULL GROUP BY mem.member_id, mem.member_name;

-- count of books not yet returned by issue month
SELECT FORMAT(iss.issued_date, 'MMMM') AS [Issued Month], COUNT (*) AS Counts
FROM books AS b 
JOIN issued_status AS iss ON b.isbn = iss.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = iss.issued_id
JOIN members AS mem ON iss.issued_member_id = mem.member_id
WHERE DATEDIFF(DAY, iss.issued_date, GETDATE()) > 30 AND rs.return_date IS NULL GROUP BY FORMAT(iss.issued_date, 'MMMM');

USE Lib_Db;

--Task 14: Update Book Status on Return
--Write a query to update the status of books in the books table to "available" when they are returned (based on entries in the return_status table).
CREATE OR ALTER PROCEDURE add_return_records 
    @p_return_id VARCHAR(100),
    @p_issued_id VARCHAR(100),
    @p_return_book_name VARCHAR(100),
    @p_return_book_isbn VARCHAR(100)
AS
BEGIN
    DECLARE @v_isbn VARCHAR(100);
    DECLARE @v_book_name VARCHAR(100);

    -- Insert the return record
    INSERT INTO return_status (return_id, issued_id, return_book_name, return_date, return_book_isbn)
    VALUES (@p_return_id, @p_issued_id, @p_return_book_name, GETDATE(), @p_return_book_isbn);

    -- Retrieve issued book information
    SELECT @v_isbn = issued_book_isbn, @v_book_name = issued_book_name
    FROM issued_status
    WHERE issued_id = @p_issued_id;

    -- Update the book status to "returned" (assuming 1 means returned)
    UPDATE books
    SET status = 1
    WHERE isbn = @v_isbn;

    -- Print a confirmation message
    PRINT 'Thank you for returning the book: ' + @v_book_name;
END;

--Task 14: Update Book Status on Return
--Write a query to update the status of books in the books table to "available" when they are returned (based on entries in the return_status table).
UPDATE books
SET [status] = CASE 
                WHEN [status] = 1 THEN 'Available'
                WHEN [status] = 0 THEN 'Not Available'
             END;
SELECT * FROM [books]

CREATE OR ALTER PROCEDURE return_books_update (@return_id VARCHAR(100), @issued_id VARCHAR(100), 
@return_book_name VARCHAR(100), @return_book_isbn VARCHAR(100) ) 
AS
DECLARE 
v_isbn VARCHAR (100)
v_name VARCHAR (100)

BEGIN
    INSERT INTO return_status(return_id, issued_id, return_book_name, return_date, return_book_isbn)
	VALUES ('@return_id', '@issued_id', '@return_book_name', GETDATE(), '@return_book_isbn')

	SELECT v_isbn = issued_book_isbn, v_name = issued_book_name
	FROM issued_status WHERE issued_id = '@issued_id';

	UPDATE books
	SET status = 'Avialable' WHERE isbn = v_isbn;


END;


SELECT * FROM books; SELECT * FROM return_status;






-- Store Procedures
CREATE OR REPLACE PROCEDURE [Add Return Records]

-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, 
-- the number of books returned, and the total revenue generated from book rentals.
SELECT * FROM branch; SELECT * FROM employees; SELECT * FROM issued_status; SELECT * FROM books;  SELECT * FROM return_status;

SELECT br.branch_id, COUNT (iss.issued_id) AS [Issued Book Counts], COUNT (rs.return_id) AS [Returned Book Counts],
SUM(b.rental_prices) AS [Total Revenue]
FROM books AS b JOIN issued_status AS iss ON b.isbn = iss.issued_book_isbn
LEFT JOIN return_status AS rs ON iss.issued_id = rs.issued_id JOIN employees AS e ON e.emp_id = iss.issued_emp_id
JOIN branch AS br ON br.branch_id = e.branch_id GROUP BY br.branch_id;


-- Task 16: CTAS: Create a Table of Active Members
-- Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 6 months.
SELECT * FROM issued_status; SELECT * FROM members;

SELECT m.member_name AS [Memeber's Name], COUNT (iss.issued_book_isbn) AS [Count Books] FROM issued_status AS iss JOIN members AS m ON
iss.issued_member_id = m.member_id GROUP BY m.member_name HAVING COUNT (iss.issued_book_isbn) > 1;

CREATE TABLE [Active Members] ([Memmber's Name] VARCHAR(100), [Count Books] INT);

INSERT INTO [Active Members]
SELECT m.member_name AS [Memeber's Name], COUNT (iss.issued_book_isbn) AS [Count Books] FROM issued_status AS iss JOIN members AS m ON
iss.issued_member_id = m.member_id GROUP BY m.member_name HAVING COUNT (iss.issued_book_isbn) > 1;

SELECT * FROM [Active Members]

-- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
USE Lib_Db;
SELECT * FROM employees; SELECT * FROM branch; SELECT * FROM issued_status; 

SELECT e.emp_name AS [Employee Name], COUNT (iss.issued_book_isbn) AS [Count Issued Books], br.branch_id AS [Branch]
FROM employees AS e JOIN issued_status AS iss ON e.emp_id = iss.issued_emp_id
JOIN branch AS br ON e.branch_id = br.branch_id GROUP BY e.emp_name, br.branch_id 
HAVING COUNT (iss.issued_book_isbn) > 3;

-- Task 18: Identify Members Issuing High-Risk Books
-- Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books.    
SELECT * FROM books;

--Task 19: Stored Procedure
--Objective: Create a stored procedure to manage the status of books in a library system.
  --  Description: Write a stored procedure that updates the status of a book based on its issuance or return. Specifically:
  --  If a book is issued, the status should change to 'no'.
   -- If a book is returned, the status should change to 'yes'. */
SELECT * FROM issued_status;
CREATE OR ALTER PROCEDURE book_records_update (@_isbn VARCHAR(100), @_issued_member_id VARCHAR (100), @issued_book_name VARCHAR (100), 
@issued_book_isbn VARCHAR (100), @issued_emp_id VARCHAR (100)
AS 

BEGIN
    INSERT INTO issued_status (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
	VALUES ('@_isbn', '@_issued_member_id', '@issued_book_name', GETDATE(), '@issued_book_isbn', '@issued_emp_id')

	UPDATE books SET [status] = 'Not Available' WHERE isbn = '@issued_book_isbn';


END;







--Task 20: Create Table As Select (CTAS)
--Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

--Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
    --The number of overdue books.
  --  The total fines, with each day's fine calculated at $0.50.
 --   The number of books issued by each member.
   -- The resulting table should show:
    -- Member ID
   -- Number of overdue books
 --   Total fines
*/


/*
### Advanced SQL Operations










