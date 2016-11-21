using BinDeps

@BinDeps.setup

liblsoda = library_dependency("liblsoda")
BinDeps.provides(Sources,URI("https://github.com/sdwfrost/liblsoda/archive/master.tar.gz"),liblsoda,unpacked_dir="liblsoda-master")

lsodadir = BinDeps.depsdir(liblsoda)

libdir=joinpath(lsodadir,"usr","lib")

srcdir = joinpath(lsodadir,"src","liblsoda-master")
builddir = joinpath(srcdir,"src")

if Sys.KERNEL == :Darwin
    suffix="dylib"
elseif Sys.KERNEL == :NT
    suffix="dll"
else
    suffix="so"
end


BinDeps.provides(SimpleBuild,
    (@build_steps begin
        BinDeps.GetSources(liblsoda)
	BinDeps.CreateDirectory(libdir)
        @build_steps begin
            BinDeps.ChangeDirectory(srcdir)
            BinDeps.MakeTargets()
        `cp $builddir/liblsoda.$suffix $libdir`
        end
end), liblsoda)
@BinDeps.install Dict(:liblsoda => :liblsoda)
