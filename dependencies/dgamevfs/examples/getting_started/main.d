import std.stdio;
import std.typecons;
import dgamevfs._;

void main()
{
    //Two filesystem directories, one read-only and the other read-write.
    auto main = new FSDir("main", "main_data/", No.writable);
    auto user = new FSDir("user", "user_data/", Yes.writable);

    //Stack directory where "user" overrides "main".
    auto stack = new StackDir("root");
    stack.mount(main);
    stack.mount(user);

    //Iterate over all files recursively, printing their VFS paths.
    foreach(file; stack.files(Yes.deep))
    {
        writeln(file.path);
    }

    VFSFile file = stack.file("new_file.txt");
    //Creates "new_file" in "user" (which is on top of "main" in the stack).
    file.output.write(cast(const void[])"Hello World!");

    //Read what we've written.
    auto buffer = new char[file.bytes];
    file.input.read(cast(void[]) buffer);

    writeln(buffer);
}

