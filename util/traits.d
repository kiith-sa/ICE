
//          Copyright Ferdinand Majerech 2010 - 2011.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module util.traits;


///Is specified type a global or static function?
template is_global_function(T){const bool is_global_function = false;}
template is_global_function(T : void function(U), U){const bool is_global_function = true;}
