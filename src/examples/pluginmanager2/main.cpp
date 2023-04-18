/*
    This file is part of Corrade.

    Original authors — credit is appreciated but not required:

        2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016,
        2017, 2018, 2019, 2020, 2021, 2022
            — Vladimír Vondruš <mosra@centrum.cz>

    This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or distribute
    this software, either in source code form or as a compiled binary, for any
    purpose, commercial or non-commercial, and by any means.

    In jurisdictions that recognize copyright laws, the author or authors of
    this software dedicate any and all copyright interest in the software to
    the public domain. We make this dedication for the benefit of the public
    at large and to the detriment of our heirs and successors. We intend this
    dedication to be an overt act of relinquishment in perpetuity of all
    present and future rights to this software under copyright law.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include <Corrade/PluginManager/Manager.hpp> /* important */
#include <Corrade/PluginManager/PluginMetadata.h>
#include <Corrade/Utility/Arguments.h>
#include <Corrade/Utility/ConfigurationGroup.h>
#include <Corrade/Utility/Debug.h>
#include <Corrade/Utility/DebugStl.h>

#include "AbstractAnimal2.h"

using namespace Corrade;

int main(int argc, char** argv) {
    /* Import static plugin using the same name as in Canary.cpp */
    CORRADE_PLUGIN_IMPORT(Canary2)

    Utility::Arguments args;
    if (false) {
        args.addArgument("plugin").setHelp("plugin", "animal plugin name")
            .setGlobalHelp("Displays info about given animal.")
            .parse(argc, argv);
    }

    /* Initialize plugin manager with given directory */
    PluginManager::Manager<Examples::AbstractAnimal2> manager;

    /* Try to load a dynamic plugin */
    if (!(manager.load("Dog2") & PluginManager::LoadState::Loaded)) {
        Utility::Error{} << "The requested plugin" << " Dog2 " << "cannot be loaded.";
        return 2;
    }

    /* Try to load a static plugin */
    if(!(manager.load("Canary2") & PluginManager::LoadState::Loaded)) {
        Utility::Error{} << "The requested plugin" << " Canary2 " << "cannot be loaded.";
        return 2;
    }

    if (true) {
        /* Instance of an animal */
        Containers::Pointer<Examples::AbstractAnimal2> animal = manager.instantiate("Dog2");

        Utility::Debug{} << "Name:     " << animal->name();
        Utility::Debug{} << "Leg count:" << animal->legCount();
        Utility::Debug{} << "Has tail: " << (animal->hasTail() ? "yes" : "no");
        Utility::Debug{} << "";
    }

    /* Instance of an animal */
    Containers::Pointer<Examples::AbstractAnimal2> animal = manager.instantiate("Canary2");

    Utility::Debug{} << "Name:     " << animal->name();
    Utility::Debug{} << "Leg count:" << animal->legCount();
    Utility::Debug{} << "Has tail: " << (animal->hasTail() ? "yes" : "no");

    return 0;
}
