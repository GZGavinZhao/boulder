/* SPDX-License-Identifier: Zlib */

/**
 * Drafter - License management
 *
 * Analyse / compare licenses
 *
 * Authors: © 2020-2022 Serpent OS Developers
 * License: ZLib
 */

module drafter.license;

public import drafter.license.engine;

/**
 * A License as found in the SPDX data set
 */
public struct License
{
    /**
     * SPDX 3.x identifier for the license
     */
    string identifier;

    /**
     * Plain text body for the license
     * We drop all whitespace + convert to lower case.
     */
    string textBody;

    /**
     * True if the license is deprecated by SPDX
     */
    bool isDeprecated;
}
