from __future__ import print_function
import temp2
import lvdb

def main():
    a = 1
    lvdb.set_trace()
    b = 2
    c = temp2.mult(a,b)
    d = temp2.div(a,b)

    print('a = ' + str(a))
    print('b = ' + str(b))
    print('c = ' + str(c))
    print('d = ' + str(d))

if __name__ == '__main__':
    main()
