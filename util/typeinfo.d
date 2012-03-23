
//          Copyright Ferdinand Majerech 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


//Runtime type information utilities.
module util.typeinfo;


///Is type a class?
bool isClass(TypeInfo type) pure nothrow
{
    return cast(TypeInfo_Class)type !is null;
}

/**
 * Is type derived from T, or does type implement T?
 *
 * If type is the same as T, it is not considered derived.
 */
bool isDerivedFrom(T)(TypeInfo type) // pure nothrow //(toString is not pure nothrow)
{
    static if(!(is(T == class) || is(T == interface)))
    {
        return false;
    }
    else
    {
        auto classType = cast(TypeInfo_Class) type;
        //type is not a class, so it can't be derived from anything
        if(classType is null){return false;}

        static if(is(T == interface))
        {
            //Comparing strings because is and == fails to work on interfaces
            const typeString = typeid(T).toString();
            if(classType.interfaces !is null) foreach(iface; classType.interfaces) 
            {
                const ifaceStr = iface.classinfo.toString;
                if(ifaceStr == typeString){return true;}
            }
        }
        else static if(is(T == class))
        {
            if(classType.base is typeid(T)){return true;}
        }
        else assert(false);

        //Done, no base class to check left
        if(classType.base is null){return false;}

        //We have a base class, so check that
        return isDerivedFrom!T(classType.base);
    }
}
unittest
{
    interface I1{}
    interface I2{}
    interface I3{}

    class B : I1, I2{}

    class D1 : B {}

    class D2 : D1, I3 {}

    assert(!isDerivedFrom!B(typeid(B)));
    assert(!isDerivedFrom!int(typeid(B)));
    assert(!isDerivedFrom!B(typeid(int)));
    assert(!isDerivedFrom!I3(typeid(B)));

    assert(isDerivedFrom!B(typeid(D1)));
    assert(isDerivedFrom!B(typeid(D2)));
    assert(isDerivedFrom!D1(typeid(D2)));

    assert(isDerivedFrom!I1(typeid(B)));
    assert(isDerivedFrom!I2(typeid(B)));
    assert(isDerivedFrom!I1(typeid(D1)));
    assert(isDerivedFrom!I1(typeid(D2)));
    assert(isDerivedFrom!I3(typeid(D2)));
}      

/**
 * Get number of bytes by an object of type T in memory.
 *
 * Unlike .sizeof, this also works for classes, i.e. size 
 * of the actual class instance, not reference, is returned.
 * 
 * For arrays, this still returns size of the "fat pointer" array,
 * object, not the size of the array content.
 */
size_t memorySize(T)() pure nothrow
    if(!is(T == interface)) 
{
    static if(is(T == class)){return __traits(classInstanceSize, T);}
    else                     {return T.sizeof;}
}
unittest
{
    struct S{int i; float f;}
    class C1{}
    class C2{int i; float f;}
    class C3 : C2 {long l;}

    assert(memorySize!float == 4);
    assert(memorySize!S == 8);
    version(X86_64)
    {
        assert(memorySize!C1 == 24);
        assert(memorySize!C2 == 32);
        assert(memorySize!C3 == 40);
    }
}
