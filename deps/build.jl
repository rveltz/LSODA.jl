using BinDeps

@BinDeps.setup

cd("/Users/rveltz/work/prog_gd/julia/LSODA.jl/deps/")
# https://github.com/sdwfrost/liblsoda
liblsoda = library_dependency("liblsoda")
BinDeps.provides(Sources,URI("https://github.com/sdwfrost/liblsoda/archive/master.tar.gz"),
	liblsoda,unpacked_dir="liblsoda-master",installed_libpath="liblsoda-master/src/")

println(BinDeps.depsdir(liblsoda))
srcdir = joinpath(BinDeps.depsdir(liblsoda),"src")
srcdir = "/Users/rveltz/work/prog_gd/julia/LSODA.jl/deps/src/liblsoda-master"
BinDeps.provides(SimpleBuild,
    (@build_steps begin
        BinDeps.GetSources(liblsoda)
        @build_steps begin
            BinDeps.ChangeDirectory(srcdir)
            `make`
			`pwd`
			# `mkdir lib`
			# `cp src/liblsoda.* lib`
        end
end), liblsoda)
@BinDeps.install Dict(:liblsoda => :liblsoda)