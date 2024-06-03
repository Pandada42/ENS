#!/usr/bin/python

import sys
import psycopg2
import psycopg2.extras


class Model:
    def __init__(self):
        self.connection = psycopg2.connect("dbname='mboyer02' user='mboyer02' host='psql.eleves.ens.fr' password='i5e4QOAq'")
        self.connection.autocommit = True
        self.cursor = self.connection.cursor(cursor_factory=psycopg2.extras.DictCursor)

    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        if (self.connection):
            self.connection.close()

##############################################
######      Queries for tab  PERSONS    ######
##############################################

    # Create a new person.
    def createPerson(self, lastname, firstname, address, phone):
        self.cursor.execute("INSERT INTO Persons (lname, fname, address, phone_number) VALUES (%s, %s, %s, %s)", (lastname, firstname, address, phone))
        self.connection.commit()

    # Return a list of (id, lastname, firstname, address, phone,
    # number of curriculums) corresponding to all persons.
    def listPersons(self):
        self.cursor.execute("""SELECT Persons.id, Persons.lname,
Persons.fname, Persons.address, Persons.phone_number,
COUNT(Programs.curriculum) FROM Persons LEFT JOIN Programs ON Persons.id =
Programs.student GROUP BY Persons.id""") 
        return self.cursor.fetchall()

    # Delete a person given its ID (beware of the foreign constraints!).
    def deletePerson(self, idPerson):
        self.cursor.executei("DELETE FROM Persons WHERE Persons.id=%s", idPerson)
        self.connection.commit()

##############################################
######     Queries for  CURRICULUMS     ######
##############################################

    # Create a curriculum.
    def createCurriculum(self, name, secretary, director):
        self.cursor.execute("INSERT INTO Curriculums (name, secretary, director) VALUES (%s , %s, %s)", (name, secretary, director))
        self.connection.commit()

    # Return a list of (id,name of curriculum,director lastname,
    # director firstname, secretary lastname, secretary firstname)
    # corresponding to all curriculums.
    def listCurriculums(self):
        self.cursor.execute("SELECT Curriculums.id, Curriculums.name, (SELECT fname FROM Persons WHERE Persons.id = Curriculums.director), (SELECT lname FROM Persons WHERE Persons.id = Curriculums.director), (SELECT fname FROM Persons WHERE Persons.id = Curriculums.secretary), (SELECT lname FROM Persons WHERE Persons.id = Curriculums.secretary) FROM Curriculums")
        return self.cursor.fetchall()

    # Delete a curriculum given its ID (beware of the foreign constraints!).
    def deleteCurriculum(self, idCurriculum):
        self.cursor.execute("DELETE FROM Persons WHERE Persons.id = %s", idCurriculum)
        self.connection.commit()

##############################################
######     Queries for  COURSES         ######
##############################################

    # Create a course.
    def createCourse(self, name, idProfessor):
        self.cursor.execute("INSERT INTO Courses (name, teacher) VALUES (%s, %s)",(name, idProfessor))
        self.connection.commit()

    # Return a list of (course id, course name, teacher id,
    # teacher last name, teacher first name) corresponding
    # to all the courses.
    def listCourses(self):
        self.cursor.execute("SELECT Courses.id, Courses.name, Courses.teacher, (SELECT fname FROM Persons WHERE Persons.id = Courses.teacher), (SELECT lname FROM Persons WHERE Persons.id = Courses.teacher) FROM Courses")
        return self.cursor.fetchall()

    # Delete a given course (beware that the course might be registered to
    # curriculum, and have grades that should also be deleted).
    def deleteCourse(self, idCourse):
        self.cursor.execute("DELETE FROM Courses WHERE Courses.id = %s", idCourse)
        self.connection.commit()


##############################################
###### Queries for tab  CURRICULUM/<ID> ######
##############################################

    # Get the name of a given curriculum.
    def getNameOfCurriculum(self, id):
        self.cursor.execute("SELECT name FROM Curriculums WHERE id = %s", id)
        return self.cursor.fetchall()[0][0]

    # Return the list (course ID, course name, course teacher
    # last name and first name, ECTS) corresponding to the courses
    # registered to a given curriculum.
    def listCoursesOfCurriculum(self, idCurriculum):
        self.cursor.execute("SELECT Courses.id, Courses.name, Courses.teacher, (SELECT fname FROM Persons WHERE Persons.id = Courses.teacher), (SELECT lname FROM Persons WHERE Persons.id = Courses.teacher) FROM Credits JOIN Courses ON Credits.class = Courses.id WHERE Credits.curriculum = %s", idCurriculum)
        return self.cursor.fetchall()

    #  !! HARD !!
    # Return a list (last name, first name, average grade) of students
    # registered to a given curriculum. The
    # average grade is computed as described in the document, but
    # beware that if a student does not have a grade for a validation
    # or is not registered to a course, he should have 0.
    def _averageGradesOfStudentsInCurriculum(self, idCurriculum):
        self.cursor.execute("SELECT SUM(Credits.credits) FROM Credits HAVING curriculum = " + idCurriculum)
        divide = self.cursor.fetchall()[0][0]
        self.cursor.execute("SELECT Persons.lname, Persons.fname, SUM(Validations.coefficient * Grades.grades * Credits.credits)/" + divide + "FROM Grades JOIN Persons ON Grades.student = Persons.id JOIN Validations ON = Validations.id = Grades.validation JOIN Credits ON Validations.class = Credits.class WHERE Credits.curriculum = " + idCurriculum + "GROUP BY Grades.student")
        return self.cursor.fetchall()

    def averageGradesOfStudentsInCurriculum(self, idCurriculum):
        self.cursor.execute("""
SELECT Persons.lname, 
    Persons.fname, 
    (SELECT
        SUM(Credits.credits * 
            (SELECT 
            SUM(Validations.coefficient * Grades.grade)/(SELECT 
                SUM(Validations.coefficient) 
                FROM Validations 
                JOIN Grades ON Validations.id = Grades.validation 
                JOIN Credits ON Validations.class = Credits.class 
                HAVING Grades.student = Persons.id AND
                Credits.curriculum = %s
                )
            )
    )/
    (SELECT SUM(Credits.credits) 
        FROM Credits
        HAVING Credits.curriculum = %s
    ) 
    FROM Validations JOIN Grades ON Validations.id = Grades.validation) 
    FROM Credits 
    JOIN Programs ON Credits.curriculum = Programs.curriculum 
    JOIN Persons ON Programs.student = Persons.id 
    GROUP BY Persons.id 
    HAVING Credits.curriculum = %s""", (idCurriculum, idCurriculum, idCurriculum))
        return self.cursor.fetchall()


    # Register a person to a curriculum.
    def registerPersonToCurriculum(self, idPerson, idCurriculum):
        self.cursor.execute("INSERT INTO Programs (curriculum, student) VALUES (%s, %s)", (idCurriculum, idPerson))
        self.connection.commit()

    # Register a course to a curriculum.
    def registerCourseToCurriculum(self, idCourse, idCurriculum, ects):
        self.cursor.execute("INSERT INTO Credits (curriculum, class, credits) VALUES (%s, %s, %s)", (idCurriculum, idCourse, ects))
        self.connection.commit()

    # Unregister a course to a curriculum.
    def deleteCourseFromCurriculum(self, idCourse, idCurriculum):
        self.cursor.execute("DELETE FROM Credits WHERE curriculum = %s AND class = %s", (idCurriculum, idCourse))
        self.connection.commit()

##############################################
######   Queries for tab  COURSE/<ID>   ######
##############################################

    # Get the name of a given course.
    def getNameOfCourse(self, id):
        self.cursor.execute("SELECT name FROM Courses WHERE id =" + id)
        # suppose that there is a solution
        return self.cursor.fetchall()[0][0]

    # Return a list of (id, name, ECTS) of the curriculums in
    # which a given course is registered.
    def listCurriculumsOfCourse(self, idCourse):
        self.cursor.execute("SELECT Credits.curriculum, Curriculums.name, Credits.ects FROM Credits JOIN CurriculumsON Credits.curriculum = Curriculums.id WHERE Credits.class = %s", idCourse)
        return self.cursor.fetchall()

    # Returns a list of (id, date, name, coefficent) for the validations
    # assiociated to a given course.
    def listValidationsOfCourse(self, idCourse):
        self.cursor.execute("SELECT Validations.id, Validations.time, Validations.name, Validations.coefficient FROM Validations WHERE Validations.class = %s", idCourse)
        return self.cursor.fetchall()

    # Return a list (id, last name, first name) of persons that are
    # registered in a curriculum with the given course
    def listStudentsOfCourse(self, idCourse):
        self.cursor.execute("SELECT Programs.student, (SELECT fname FROM Persons WHERE Persons.id = Programs.student), (SELECT lname FROM Persons WHERE Persons.id = Programs.student) FROM Programs JOIN Credits ON Credits.curriculum = Programs.curriculum WHERE Credits.class = %s", idCourse)
        return self.cursor.fetchall()

    # Return a list (id, date, curriculum name, student last name,
    # student first name, validation name, grade, coefficient) of
    # grades for all the validations and students having taken them,
    # sorted by decreasing date of validation.
    def listGradesOfCourse(self, idCourse):
        self.cursor.execute("SELECT Grades.id, Validations.date, (SELECT Curriculums.name FROM Curriculums JOIN Programs ON Curriculums.id = Programs.curriculum WHERE Programs.student = Grades.student), SELECT fname FROM Persons WHERE Persons.id = Grades.student), (SELECT lname FROM Persons WHERE Persons.id = Grades.student), Validations.name, Grades.grade, Validations.coefficient FROM Grades JOIN Validations ON Grades.validation = Validations.id WHERE Validations.class = %s ORDER BY Validations.date DESC", idCourse)
        return self.cursor.fetchall()

    # Add a validation to a given course.
    def addValidationToCourse(self, name, coef, date, idCourse):
        self.cursor.execute("INSERT INTO Validations (class, name, time, coefficient) VALUES (%s, %s, %s, %s)", (idCourse, name, date, coef))
        self.connection.commit()

    # Add a grade to a student.
    def addGrade(self, idValidation, idStudent, grade):
        self.cursor.execute("INSERT INTO Grades (validation, student, grade) VALUES (%s, %s, %s)", (idValidation, idStudent, grade))
        self.connection.commit()

##############################################
######       Queries for tab            ######
######      COURSE/<ID1>/<ID2           ######
###### corresponding to validations     ######
##############################################

   # Return a list (grade, lastname, firstname) of grades for
   # a given validation.
    def listGradesOfValidation(self, idValidation):
        self.cursor.execute("SELECT Grades.grade, Persons.lname, Persons.fname FROM Grades JOIN Persons ON Grades.student = Persons.id WHERE Grades.validation = %s", idValidation)
        return self.cursor.fetchall()

    # Get the complete name of a validation given its ID. The
    # complete name of a validation with name "exam" of a course "BDD"
    # is "BDD - exam". You should therefore preppend the name of the
    # course.
    def getNameOfValidation(self, id):
        self.cursor.execute("SELECT CONCAT(Courses.name, ' - ', Validations.name) FROM Validations JOIN Courses ON Validations.class = Courses.id WHERE Validations.id = %s", id)
        # suppose that there is a solution
        return self.cursor.fetchall()[0][0]

##############################################
######   Queries for tab  PERSON/<ID>   ######
##############################################

    # Get the name of a person given its ID.
    def getNameOfPerson(self, id):
        self.cursor.execute("SELECT CONCAT(fname, ' ', lname) FROM Persons WHERE id = %s", id)
        # suppose that there is a solution
        return self.cursor.fetchall()[0][0]

    # Return a list (id, date, curriculum name, course name,
    # exam name, grade) of grades for a given student, sorted
    # by decreasing date of validation.
    def listValidationsOfStudent(self, idStudent):
        self.cursor.execute("SELECT Grades.id, Validations.time, (SELECT Curriculums.name FROM Curriculums JOIN Programs ON Curriculums.id = Programs.curriculum WHERE Programs.student = Grades.student), (SELECT Courses.name FROM Courses WHERE Courses.id = Validations.class), Validations.name, Grades.grade FROM Grades JOIN Validations ON Grades.validation = Validations.id WHERE Grades.student = %s ORDER BY Validations.time DESC", idStudent)
        return self.cursor.fetchall()

    # !!! HARD !!!
    # Return a list (curriculum name, average grade) of all the
    # curriculum a given student is registered to, where the
    # average grade is computed as before.
    def listCurriculumsOfStudent(self, idStudent):
        self.cursor.execute("SELECT Curriculums.name, SUM(Credits.credits * Grades.grade)/(SELECT SUM(Credits.credits) FROM Credits HAVING Credits.curriculum = Curriculums.id) FROM Curriculums JOIN Programs ON Programs.curriculum = Curriculums.id JOIN Grades ON ")
        return self.cursor.fetchall()
