/* SPDX-License-Identifier: Zlib */

/**
 * Stage: Populate root
 *
 * Populate root with useful packages
 *
 * Authors: © 2020-2022 Serpent OS Developers
 * License: ZLib
 */

module boulder.stages.populate_root;

public import boulder.stages : Stage, StageReturn, StageContext;
import mason.build.util : executeCommand, ExecutionError;
import std.sumtype : match;

/**
 * Go ahead and configure the tree
 *
 */
public static immutable(Stage) stagePopulateRoot = Stage("populate-root", (StageContext context) {
    /* TODO: Find a way to not hardcode these? */
    auto requiredInstalled = [
        "bash", "boulder", "coreutils", "dash", "diffutils", "gawk", "glibc-devel",
        "grep", "fakeroot", "findutils", "libarchive", "linux-headers",
        "pkgconf", "sed", "util-linux"
    ];
    auto requiredEMUL32 = ["glibc-32bit-devel"];

    /* Needed packages for GNU builds */
    auto requiredGNU = ["binutils", "gcc-devel"];
    auto requiredGNU32 = ["gcc-32bit-devel"];

    /* Needed packages for LLVM builds */
    auto requiredLLVM = ["clang"];
    auto requiredLLVM32 = ["clang-32bit", "libcxx-32bit-devel"];

    /* Append 32bit packages if enabled in the stone.yml */
    if (context.job.recipe.options.emul32)
    {
        requiredInstalled ~= requiredEMUL32;
        requiredGNU ~= requiredGNU32;
        requiredLLVM ~= requiredLLVM32;
    }

    /* Append additional packages to support the toolchain in use */
    if (context.job.recipe.options.toolchain == "llvm")
    {
        requiredInstalled ~= requiredLLVM;
    }
    else
    {
        requiredInstalled ~= requiredGNU;
    }

    /* TODO: Extend to other architectures.. */
    requiredInstalled ~= context.job.recipe.rootBuild.buildDependencies;
    requiredInstalled ~= context.job.recipe.rootBuild.checkDependencies;

    string[string] env;
    env["PATH"] = "/usr/bin";
    auto result = executeCommand(context.mossBinary, [
            "install", "-D", context.job.hostPaths.rootfs
        ] ~ requiredInstalled, env);
    return result.match!((i) => i == 0 ? StageReturn.Success
        : StageReturn.Failure, (ExecutionError e) => StageReturn.Failure);
});
