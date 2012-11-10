
//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


///Extremely simple unittest framework working similarly to D's builtin tests.
///
///This was added to avoid some DMD bugs with memory allocation 
///before main() that made builtin unittests useless.
module util.unittests;

import std.stdio;

///Run all registered unittests.
///
///Called by main() at startup.
void runUnitTests()
{
    writeln("Running unittests");
    foreach(test; UNITTEST_TESTS_[0 .. UNITTEST_TESTCOUNT_])
    {
        test();
    }
}

///Register a unittest to be run at the beginning of main().
///
///Params:  testFunction = Unittest funtion. Asserts mean test failure.
///         testName     = Name of the unittest.
mixin template registerTest(alias testFunction, string testName)
{
    static this()
    {
        // Do not unittest in release (asserts are disabled anyway)
        debug 
        {
            import std.stdio;
            writeln("Registering test ", testName);
            if(UNITTEST_TESTCOUNT_ == UNITTEST_TESTS_.length)
            {
                writeln("WARNING: too many tests, refusing to register any more. " ~
                        "Increase test capacity.");
                return;
            }
            void delegate() test = 
            {
                writeln("starting test: ", testName);
                scope(success){writeln("test succeeded");}
                scope(failure){writeln("test FAILED");}
                testFunction();
            };
            UNITTEST_TESTS_[UNITTEST_TESTCOUNT_++] = test;
        }
    }
}


// Registered tests.
//
// Fixed size to avoid potential compiler bugs.
void delegate() [2048] UNITTEST_TESTS_;

// Number of tests in tests_.
uint UNITTEST_TESTCOUNT_ = 0;
