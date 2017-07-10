class mailData:

   def sendMail(self):
       print ("Sending Mail")

   def fwdMail(self):
       print ("Forwarding email")
  
   def ccMail(self):
       print ("Cc email")


def main():
 
     mymail = mailData()

     mymail.sendMail()
     mymail.fwdMail()
     mymail.ccMail()


main()
