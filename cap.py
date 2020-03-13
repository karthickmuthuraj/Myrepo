def capitalize(string):
    new_string=""
    i=0
    max=len(string)
    while(i<max):
        if i==0:
            new_string =string[i].capitalize()
        elif string[i].isspace():
            new_string +="".join(string[i])
            new_string += "".join(string[i+1].capitalize())
            i=i+2
            continue
        else:
            new_string+="".join(string[i])
        i=i+1
    return new_string



string="hello world"
capitalized = capitalize(string)

print capitalized 
