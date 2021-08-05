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

module boulder.build.context;

import moss.format.source.macros;
import moss.format.source.spec;
import moss.format.source.script;

import std.parallelism : totalCPUs;
import std.concurrency : initOnce;

/**
 * Return the current shared Context for all moss operations
 */
BuildContext buildContext() @trusted
{
    return initOnce!_sharedBuildContext(new BuildContext());
}

/* Singleton instance */
private __gshared BuildContext _sharedBuildContext = null;

/**
 * The BuildContext holds global configurations and variables needed to complete
 * all builds.
 */
public final class BuildContext
{
    /**
     * Construct a new BuildContext
     */
    this()
    {
        this._spec = spec;
        this._rootDir = ".";

        jobs = 0;

        this.loadMacros();
    }

    /**
     * Return the spec (recipe) directory
     */
    pure @property string specDir() const @safe @nogc nothrow
    {
        return _specDir;
    }

    /**
     * Set the spec (recipe) directory
     */
    pure @property void specDir(const(string) p) @safe @nogc nothrow
    {
        _specDir = p;
    }

    /**
     * Return the root directory
     */
    pure @property string rootDir() const @safe @nogc nothrow
    {
        return _rootDir;
    }

    /**
     * Set the new root directory
     */
    pure @property void rootDir(const(string) s) @safe @nogc nothrow
    {
        _rootDir = s;
    }

    /**
     * Return the package file directory
     */
    pure @property string pkgDir() const @safe nothrow
    {
        import std.path : buildPath;

        return _rootDir.buildPath("pkgdir");
    }

    /**
     * Return the source directory
     */
    pure @property string sourceDir() const @safe nothrow
    {
        import std.path : buildPath;

        return _rootDir.buildPath("sourcedir");
    }

    /**
     * Return the underlying specfile
     */
    pragma(inline, true) pure @property scope Spec* spec() @safe @nogc nothrow
    {
        return _spec;
    }

    /**
     * Update the currently used spec for this BuildContext
     */
    pure @property void spec(Spec* spec) @safe @nogc nothrow
    {
        _spec = spec;
    }

    /**
     * Return the number of build jobs
     */
    pure @property int jobs() @safe @nogc nothrow
    {
        return _jobs;
    }

    /**
     * Set the number of build jobs
     */
    @property void jobs(int j) @safe @nogc nothrow
    {
        if (j < 1)
        {
            _jobs = totalCPUs();
            return;
        }

        _jobs = j;
    }

    /**
     * Return the outputDirectory property
     */
    pure @property const(string) outputDirectory() @safe @nogc nothrow
    {
        return _outputDirectory;
    }

    /**
     * Set the outputDirectory property
     */
    pure @property void outputDirectory(const(string) s) @safe @nogc nothrow
    {
        _outputDirectory = s;
    }

    /**
     * Prepare a ScriptBuilder
     */
    void prepareScripts(ref ScriptBuilder sbuilder, string architecture)
    {
        import std.stdio : writefln;
        import std.conv : to;

        string[] arches = ["base", architecture];

        sbuilder.addDefinition("name", spec.source.name);
        sbuilder.addDefinition("version", spec.source.versionIdentifier);
        sbuilder.addDefinition("release", to!string(spec.source.release));
        sbuilder.addDefinition("jobs", to!string(jobs));
        sbuilder.addDefinition("pkgdir", pkgDir);
        sbuilder.addDefinition("sourcedir", sourceDir);

        foreach (ref arch; arches)
        {
            auto archFile = defFiles[arch];
            sbuilder.addFrom(archFile);
        }

        foreach (ref action; actionFiles)
        {
            sbuilder.addFrom(action);
        }
    }

private:

    /**
     * Load all supportable macros
     */
    void loadMacros()
    {
        import std.file : exists, dirEntries, thisExePath, SpanMode;
        import std.path : buildPath, dirName, baseName;
        import moss.core.platform : platform;
        import std.string : format;
        import std.exception : enforce;

        MacroFile* file = null;

        string resourceDir = "/usr/share/moss/macros";
        string actionDir = null;
        string localDir = dirName(thisExePath).buildPath("..", "data", "macros");

        /* Prefer local macros */
        if (localDir.exists())
        {
            resourceDir = localDir;
        }

        auto plat = platform();
        actionDir = resourceDir.buildPath("actions");

        /* Architecture specific YMLs that MUST exist */
        string baseYml = resourceDir.buildPath("base.yml");
        string nativeYml = resourceDir.buildPath("%s.yml".format(plat.name));
        string emulYml = resourceDir.buildPath("emul32", "%s.yml".format(plat.name));

        enforce(baseYml.exists, baseYml ~ " file cannot be found");
        enforce(nativeYml.exists, nativeYml ~ " cannot be found");
        if (plat.emul32)
        {
            enforce(emulYml.exists, emulYml ~ " cannot be found");
        }

        /* Load base YML */
        file = new MacroFile(File(baseYml));
        file.parse();
        defFiles["base"] = file;

        /* Load arch specific */
        file = new MacroFile(File(nativeYml));
        file.parse();
        defFiles[plat.name] = file;

        /* emul32? */
        if (plat.emul32)
        {
            file = new MacroFile(File(emulYml));
            file.parse();
            defFiles["emul32/%s".format(plat.name)] = file;
        }

        if (!actionDir.exists)
        {
            return;
        }

        /* Load all the action files in */
        foreach (nom; dirEntries(actionDir, "*.yml", SpanMode.shallow, false))
        {
            if (!nom.isFile)
            {
                continue;
            }
            auto name = nom.name.baseName[0 .. $ - 4];
            file = new MacroFile(File(nom.name));
            file.parse();
            actionFiles ~= file;
        }
    }

    string _rootDir;
    Spec* _spec;

package:
    MacroFile*[string] defFiles;
    MacroFile*[] actionFiles;
    uint _jobs = 0;
    string _outputDirectory = ".";
    string _specDir = ".";
}
