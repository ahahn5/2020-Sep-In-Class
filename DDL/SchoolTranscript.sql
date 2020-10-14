/* **********************************************
 * Simple Table Creation - Columns and Primary Keys
 *
 * School Transcript
 *  Version 1.0.0
 *
 * Author: Dan Gilleland
 ********************************************** */
-- Create the database
IF NOT EXISTS (SELECT name FROM master.sys.databases WHERE name = N'SchoolTranscript')
BEGIN
    CREATE DATABASE [SchoolTranscript] -- Will create a new database with some default tables (INFORMATION_SCHEMA.TABLES) inside
END
GO

-- Switch execution context to the database
USE [SchoolTranscript] -- remaining SQL statements will run against the SchoolTranscript database
GO

-- Drop Tables
--  Drop them in the REVERSE ORDER I created them
IF EXISTS(SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'StudentCourses')
    DROP TABLE StudentCourses
IF EXISTS(SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'Courses')
    DROP TABLE Courses
IF EXISTS(SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'Students')
    DROP TABLE Students

-- SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES

-- Create Tables...
--    Build them in an order that supports the FK constraints
-- My personal coding convention is to keep all SQL keywords in UPPER CASE except for data types (lower case)
-- and all object names (Tables, ColumnNames, etc.) as TitleCase.

-- A Table Definition consists of a comma-separated list
-- of Column Definitions and Table Constraints.
-- Column Definitions can include adding one or more constraints
-- to the column. It is a good idea to give a name to your
-- constraints. Use the following prefixes:
-- - PK - Primary Key
-- - FK - Foreign Key
-- - DF - Default
-- - CK - Check
-- Additional prefixes on named items in our table definitions
-- - IX - Indexes
-- - UX - Unique constraints
CREATE TABLE Students -- The default "schema" name is [dbo] - a "schema" is a subset of a database
(
    -- Our column definitions will describe the
    -- name of the column and its data type as well as
    -- any "constraints" or "restrictions" around the data
    -- that can be stored in that column
    StudentID       int
        CONSTRAINT PK_Students_StudentID PRIMARY KEY
        -- A PRIMARY KEY constraint prevents duplicate data
        IDENTITY (2000, 5)
        -- An IDENTITY constraint means that the database server
        -- will take responsibility to put a value in this column
        -- every time a new row is added to the table.
        -- IDENTITY constraints can only be applied to PRIMARY KEY
        -- columns that are of a whole-number numeric type.
        -- The IDENTITY constraint takes two values
        --  - The "seed" or starting value for the first row inserted
        --  - The "increment" or amount by which the values increase
                                NOT NULL,
    GivenName       varchar(50)
        CONSTRAINT CK_Students_GivenName
            CHECK (GivenName LIKE '[A-Z][A-Z]%')
            -- Matches 'Dan' or 'Danny' or 'Jo'
                                NOT NULL,
    Surname         varchar(50)
        CONSTRAINT CK_Students_Surname
            CHECK (Surname LIKE '__%') -- Not as good as [A-Z][A-Z]%
                                       -- Silly matches: 42
                                NOT NULL,
    DateOfBirth     datetime    NOT NULL,
    Enrolled        bit -- Holds values of either 1 or 0
        CONSTRAINT DF_Students_Enrolled
            DEFAULT (1)
        -- A DEFAULT constraint means that if no data is supplied
        -- for this column, it will automatically use the default.
                                NOT NULL
)

CREATE TABLE Courses
(
    [Number]        varchar(10)
        CONSTRAINT PK_Courses_Number PRIMARY KEY
        CONSTRAINT CK_Courses_Number
            CHECK ([Number] LIKE '[A-Z][A-Z][A-Z][A-Z]-[0-9][0-9][0-9][0-9]')
                                    NOT NULL,
    [Name]          varchar(50)     NOT NULL,
    Credits         decimal(3, 1)
        CONSTRAINT CK_Courses_Credits
            CHECK (Credits IN (3, 4.5, 6))
                                   NOT NULL,
    [Hours]         tinyint
        CONSTRAINT CK_Courses_Hours
            CHECK ([Hours] = 60 OR [Hours] = 90 OR [Hours] = 120)
            --     [Hours] IN (60, 90, 120)
                                    NOT NULL,
    Active          bit             NOT NULL,
    Cost            money
        CONSTRAINT CK_Courses_Money
            CHECK (Cost BETWEEN 400.00 AND 1500.00)
        -- A CHECK constraint will ensure that the value passed in
        -- meets the requirements of the constraint.
                                    NOT NULL,
    -- Table-Level constraints are used for anything involving more than
    -- one column, such as Composite Primary Keys or complex CHECK constraints.
    -- It's a good pattern to put table-level constraint AFTER you have done all the
    -- column definitions.
    CONSTRAINT CK_Courses_Credits_Hours
        CHECK ([Hours] IN (60, 90) AND Credits IN (3, 4.5) OR [Hours] = 120 AND Credits = 6)
        --     \       #1        /
        --                             \       #2        /
        --             \            #3          /
        --                                                    \      #4   /
        --                                                                      \     #5  /
        --                                                           \       #6        /
        --                          \                     #7                  /
)

CREATE TABLE StudentCourses
(
    StudentID       int
        CONSTRAINT FK_StudentCourses_Students
            FOREIGN KEY REFERENCES Students(StudentID)
        -- A FOREIGN KEY constraint means that the only values
        -- acceptable for this column must be values that exist
        -- in the referenced table.
                                    NOT NULL,
    CourseNumber    varchar(10)
        CONSTRAINT FK_StudentCourses_Courses -- All constraint names have to be unique
            FOREIGN KEY REFERENCES Courses([Number])
                                    NOT NULL,
    [Year]          smallint
        CONSTRAINT CK_StudentCourses_Year
            CHECK ([Year] > 2010)
            --     NOT [Year] <= 2010
                                    NOT NULL,
    Term            char(3)         NOT NULL,
    FinalMark       tinyint
        CONSTRAINT CK_StudentCourses_FinalMark
            CHECK (FinalMark BETWEEN 0 AND 100)
            --     FinalMark >= 0 AND FinalMark <=100
                                        NULL, -- can be empty
    [Status]        char(1)
        CONSTRAINT CK_StudentCourses_Status
            CHECK ([Status] LIKE '[AWE]')
            --     [Status] = 'A' OR [Status] = 'E' OR [Status] = 'W'
            --     [Status] IN ('A','W','E')
                                    NOT NULL,
    -- Table-Level Constraint - when a constraint involves more than one column
    CONSTRAINT PK_StudentCourse_StudentID_CourseNumber
        PRIMARY KEY (StudentID, CourseNumber)
        -- Composite Primary Key constraint
)
-- Naming convention for constraints:
-- PREFIX_Tablename_ColumnName  <- PK, CK, DF
-- FK_TableName_RelatedTableName