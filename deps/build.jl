using BinDeps

@BinDeps.setup

liblsoda = library_dependency("liblsoda")
BinDeps.provides(Sources,URI("https://github.com/sdwfrost/liblsoda/archive/v0.1.1.tar.gz"),liblsoda,unpacked_dir="liblsoda-0.1.1")

lsodadir = BinDeps.depsdir(liblsoda)

libdir=joinpath(lsodadir,"usr","lib")

srcdir = joinpath(lsodadir,"src","liblsoda-0.1.1")
builddir = joinpath(srcdir,"src")

provides(Binaries,
    URI("https://dl.bintray.com/sdwfrost/generic/liblsoda.7z"),
    [liblsoda], unpacked_dir="bin$(Sys.WORD_SIZE)",
    os = :Windows)

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
end), [liblsoda], os = :Unix)
@BinDeps.install Dict(:liblsoda => :liblsoda)
