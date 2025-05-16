-- ============================================
-- Library Loan Extension System
-- Version: 1.3 - Final Corrected Version
-- ============================================

SET ECHO OFF

PROMPT ============================================
PROMPT Creating Loan Extension System Components
PROMPT ============================================

PROMPT Dropping existing objects if they exist...

-- Drop sequence
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE loan_extension_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN RAISE; END IF;
END;
/

-- Drop log table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE LoanExtensionLog CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

-- Drop trigger
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_loan_extension';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -4080 THEN RAISE; END IF;
END;
/

-- Drop procedure
BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE extend_loan';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -4043 THEN RAISE; END IF;
END;
/

-- Drop views
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW v_eligible_loans';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW v_loan_extension_history';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN RAISE; END IF;
END;
/

PROMPT Creating sequence...
CREATE SEQUENCE loan_extension_seq
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

PROMPT Creating LoanExtensionLog table...
CREATE TABLE LoanExtensionLog (
    ExtensionID     NUMBER PRIMARY KEY,
    LoanID          VARCHAR2(10),
    MemberID        VARCHAR2(10),
    ExtensionDate   DATE DEFAULT SYSDATE,
    ExtendedBy      VARCHAR2(30)
);

PROMPT Creating AFTER INSERT/UPDATE trigger on Members table...
CREATE OR REPLACE TRIGGER trg_loan_extension
AFTER INSERT OR UPDATE ON Members
FOR EACH ROW
BEGIN
    INSERT INTO LoanExtensionLog (
        ExtensionID, LoanID, MemberID, ExtensionDate, ExtendedBy
    ) VALUES (
        loan_extension_seq.NEXTVAL,
        NULL,
        :NEW.MemberID,
        SYSDATE,
        USER
    );
END;
/

PROMPT Creating extend_loan procedure...
CREATE OR REPLACE PROCEDURE extend_loan (
    p_LoanID      IN VARCHAR2,
    p_MemberID    IN VARCHAR2,
    p_ExtendedBy  IN VARCHAR2
) IS
BEGIN
    -- Log the extension
    INSERT INTO LoanExtensionLog (
        ExtensionID, LoanID, MemberID, ExtensionDate, ExtendedBy
    ) VALUES (
        loan_extension_seq.NEXTVAL,
        p_LoanID,
        p_MemberID,
        SYSDATE,
        p_ExtendedBy
    );

    -- Extend due date by 7 days
    UPDATE Loan
    SET DueDate = DueDate + 7
    WHERE LoanID = p_LoanID AND MemberID = p_MemberID;

    COMMIT;
END;
/

PROMPT Creating views...
-- View for loans eligible for extension (example: due in next 7 days)
-- Corrected View for loans eligible for extension
CREATE OR REPLACE VIEW v_eligible_loans AS
SELECT
    l.LoanID,
    l.MemberID,
    m.FirstName || ' ' || m.LastName AS MemberName,
    l.DueDate,
    l.LoanStatus AS Status,
    bc.BookCopyID,
    b.BookTitle
FROM
    Loan l
    JOIN Members m ON l.MemberID = m.MemberID
    JOIN BookCopy bc ON l.BookCopyID = bc.BookCopyID
    JOIN Book b ON bc.BookID = b.BookID
WHERE
    l.DueDate > SYSDATE
    AND l.DueDate <= SYSDATE + 7
    AND l.LoanStatus = 'VALID'
    AND m.MembershipStatus = 'ACTIVE';

-- Corrected View for loan extension history
CREATE OR REPLACE VIEW v_loan_extension_history AS
SELECT
    le.ExtensionID,
    le.LoanID,
    le.MemberID,
    m.FirstName || ' ' || m.LastName AS MemberName,
    le.ExtensionDate,
    le.ExtendedBy
FROM
    LoanExtensionLog le
    LEFT JOIN Members m ON le.MemberID = m.MemberID;

PROMPT ============================================
PROMPT Loan Extension System installed successfully
PROMPT ============================================

SET FEEDBACK ON
SET VERIFY ON
SET TIMING OFF
