/*
 * Souffle - A Datalog Compiler
 * Copyright (c) 2013, 2014, Oracle and/or its affiliates. All rights reserved
 * Licensed under the Universal Permissive License v 1.0 as shown at:
 * - https://opensource.org/licenses/UPL
 * - <souffle root>/licenses/SOUFFLE-UPL.txt
 */

/************************************************************************
 *
 * @file RamTypes.h
 *
 * Defines tuple element type and data type for keys on table columns
 *
 ***********************************************************************/

#pragma once

#include <limits>

#include <cstdint>
#include <type_traits>

namespace souffle {

/**
 * Type of an element in a tuple.
 *
 * Default type is int32_t; may be overridden by user
 * defining RAM_DOMAIN_TYPE.
 */

#ifndef RAM_DOMAIN_SIZE
#define RAM_DOMAIN_SIZE 32
#endif

#if RAM_DOMAIN_SIZE == 64
using RamDomain = int64_t;
using RamSigned = int64_t;
using RamUnsigned = uint64_t;
// There is not standard fixed size float.
using RamFloat = double;
#else
using RamDomain = int32_t;
using RamSigned = int32_t;
using RamUnsigned = uint32_t;
// There is no standard - fixed size float.
using RamFloat = float;
#endif

static_assert(std::is_integral<RamSigned>::value && std::is_signed<RamSigned>::value);
static_assert(std::is_integral<RamUnsigned>::value && !std::is_signed<RamUnsigned>::value);
static_assert(std::is_floating_point<RamFloat>::value);

    
/** lower and upper boundaries for the ram domain **/
#define MIN_RAM_DOMAIN (std::numeric_limits<RamDomain>::min())
#define MAX_RAM_DOMAIN (std::numeric_limits<RamDomain>::max())

/** search signature of a RAM operation; each bit represents an attribute of a relation.
 * A one represents that the attribute has an assigned value; a zero represents that
 * no value exists (i.e. attribute is unbounded) in the search. */
using SearchSignature = uint64_t;

}  // end of namespace souffle
