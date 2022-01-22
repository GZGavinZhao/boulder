/*
 * This file is part of boulder.
 *
 * Copyright © 2020-2021 Serpent OS Developers
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

module mason.build.stage;

import mason.build.profile : BuildProfile;

/**
 * Valid stage types.
 */
enum StageType
{
    /** Special internal preparation step */
    Prepare = 1 << 0,

    /** The initial setup (configure) state */
    Setup = 1 << 1,

    /** Perform all real building */
    Build = 1 << 2,

    /** Install contents to collection tree */
    Install = 1 << 3,

    /** Check consistency of the software */
    Check = 1 << 4,

    /** Profile Guided Optimisation generation step */
    Workload = 1 << 5,

    /** Stage1/LLVM PGO generation */
    ProfileStage1 = 1 << 6,

    /** Stage2/LLVM PGO regeneration */
    ProfileStage2 = 1 << 7,

    /** We need to use PGO data */
    ProfileUse = 1 << 8,
}

/**
 * An ExecutionStage is a single step within the build process.
 * It contains the execution script required to run as well as the name,
 * working directory, etc.
 */
struct ExecutionStage
{

public:

    @disable this();

    /**
     * Construct a new ExecutionStage from the given parent profile
     */
    this(BuildProfile* parent, StageType stageType)
    {
        _parent = parent;
        _script = null;
        _type = stageType;

        if ((stageType & StageType.Setup) == StageType.Setup)
        {
            _name = "setup";
        }
        else if ((stageType & StageType.Build) == StageType.Build)
        {
            _name = "build";
        }
        else if ((stageType & StageType.Install) == StageType.Install)
        {
            _name = "install";
        }
        else if ((stageType & StageType.Check) == StageType.Check)
        {
            _name = "check";
        }
        else if ((stageType & StageType.Workload) == StageType.Workload)
        {
            _name = "workload";
        }
        else if ((stageType & StageType.Prepare) == StageType.Prepare)
        {
            _name = "prepare";
        }

        /* PGO generation */
        if ((stageType & StageType.ProfileStage1) == StageType.ProfileStage1)
        {
            _name ~= "-pgo-stage1";
        }
        else if ((stageType & StageType.ProfileStage2) == StageType.ProfileStage2)
        {
            _name ~= "-pgo-stage2";
        }
        else if ((stageType & StageType.ProfileUse) == StageType.ProfileUse)
        {
            _name ~= "-pgo-use";
        }
    }

    /**
     * Return the name for this stage
     */
    pure @property string name() @safe @nogc nothrow
    {
        return _name;
    }

    /**
     * Return the parent build profile
     */
    pure @property BuildProfile* parent() @safe @nogc nothrow
    {
        return _parent;
    }

    /**
     * Return the underlying script.
     */
    pure @property string script() @safe nothrow
    {
        return _script;
    }

    /**
     * Set the script to a new string
     */
    @property void script(in string sc) @safe
    {
        import std.string : strip;

        _script = "%scriptBase\n" ~ sc.strip;
    }

    /**
     * Return type of stage
     */
    pure @property StageType type() @safe @nogc nothrow
    {
        return _type;
    }

private:

    BuildProfile* _parent = null;
    string _name = null;
    StageType _type = StageType.Build;
    string _script = null;
}
