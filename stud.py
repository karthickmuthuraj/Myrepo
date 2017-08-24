#!/usr/bin/python 

class Stud:

   def __init__(self,name,contact):
          self.name = name
          self.contact = contact 

   def getdata(self):
          print("Accepting Data")
          self.name = raw_input("Enter the name:")
          self.contact = raw_input("Enter the contact number:")
            

   def putdata(self):
          print("Name:", self.name)
          print("Contact:", self.contact)

class ScienceStud(Stud):
      def __init__(self,age):
             self.age = age

      def science(self):
           print("I am in Science Student")


#obj = Stud("blank",0)
#obj.getdata()
#obj.putdata()

Rob = ScienceStud(20)

Rob.science()
Rob.getdata()
Rob.putdata()
