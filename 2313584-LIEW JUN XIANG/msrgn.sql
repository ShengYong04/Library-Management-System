-- ============================================
-- Membership Registration Module
-- ============================================

-- Drop existing objects if needed
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_generate_member_id';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_member_id';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE Membership CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Create Membership table
CREATE TABLE Membership (
    MemberID           CHAR(8)         PRIMARY KEY,
    Name               VARCHAR2(100)   NOT NULL,
    ICNumber           VARCHAR2(12)    NOT NULL,
    Gender             CHAR(1)         CHECK (Gender IN ('M', 'F')),
    DateOfBirth        DATE            NOT NULL,
    PhoneNumber        VARCHAR2(14)    NOT NULL,
    Email              VARCHAR2(80)    NOT NULL,
    Address            VARCHAR2(255)   NOT NULL,
    RegistrationDate   DATE            DEFAULT SYSDATE,
    MembershipStatus   VARCHAR2(10)    DEFAULT 'ACTIVE' CHECK (UPPER(MembershipStatus) IN ('ACTIVE', 'INACTIVE'))
);

-- Create a sequence for MemberID
CREATE SEQUENCE seq_member_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE;

-- Trigger to auto-generate MemberID
CREATE OR REPLACE TRIGGER trg_generate_member_id
BEFORE INSERT ON Membership
FOR EACH ROW
BEGIN
    SELECT 'MB' || LPAD(seq_member_id.NEXTVAL, 6, '0')
    INTO :NEW.MemberID
    FROM dual;
END;
/

-- Procedure for Member Registration
CREATE OR REPLACE PROCEDURE RegisterMember (
    p_Name             IN VARCHAR2,
    p_ICNumber         IN VARCHAR2,
    p_Gender           IN CHAR,
    p_DateOfBirth      IN DATE,
    p_PhoneNumber      IN VARCHAR2,
    p_Email            IN VARCHAR2,
    p_Address          IN VARCHAR2,
    p_MembershipStatus IN VARCHAR2 DEFAULT 'ACTIVE'
) AS
BEGIN
    INSERT INTO Membership (
        Name, ICNumber, Gender, DateOfBirth,
        PhoneNumber, Email, Address, MembershipStatus
    ) VALUES (
        p_Name, p_ICNumber, p_Gender, p_DateOfBirth,
        p_PhoneNumber, p_Email, p_Address, p_MembershipStatus
    );
END;
/

-- Test data
BEGIN
    RegisterMember(
        p_Name => 'John Doe',
        p_ICNumber => '900101011234',
        p_Gender => 'M',
        p_DateOfBirth => TO_DATE('1990-01-01', 'YYYY-MM-DD'),
        p_PhoneNumber => '(012) 3456789',
        p_Email => 'johndoe@example.com',
        p_Address => '123 Main Street, Cityville'
    );

    RegisterMember(
        p_Name => 'Jane Smith',
        p_ICNumber => '920202022345',
        p_Gender => 'F',
        p_DateOfBirth => TO_DATE('1992-02-02', 'YYYY-MM-DD'),
        p_PhoneNumber => '(013) 9876543',
        p_Email => 'janesmith@example.com',
        p_Address => '456 Elm Street, Townsville'
    );
END;
/

CREATE OR REPLACE VIEW v_membership_list AS
SELECT
  MemberID,
  Name,
  ICNumber,
  Gender,
  TO_CHAR(DateOfBirth, 'DD-MON-YYYY') AS DOB,
  PhoneNumber,
  Email,
  Address,
  TO_CHAR(RegistrationDate, 'DD-MON-YYYY') AS RegDate,
  MembershipStatus
FROM Membership;

SELECT * FROM v_membership_list;