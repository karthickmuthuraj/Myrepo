import random,string

def randomstr(length):
    return ''.join(random.choice( "i." +string.lowercase + string.digits) for i in range(length))


print randomstr(16)
