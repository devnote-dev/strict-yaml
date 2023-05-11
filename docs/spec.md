# StrictYAML Specification

**Revision:** 0.1.0 (11-05-2023)

## Contents

1. [Introduction](#1-introduction)
2. [Overview](#2-overview)
3. [Differentiation](#3-differentiation)
4. [Data Types](#4-data-types)
    * A. Scalars
    * B. Booleans
    * C. Null
    * D. Numbers
    * E. Mappings
        - Complexes
    * F. Lists
5. [Other Constructs](#5-other-constructs)
    * A. Anchors and References
    * B. Tags
    * C. Directives
6. [Implementation](#6-implementation)
7. [Index](#7-index)

## 1. Introduction

TODO.

## 2. Overview

StrictYAML is very similar to the original strictyaml implementation, with a few additional changes.

* **Booleans can only be `true` or `false`.** This was stated but not necessarily enforced in the original implementation. Alongside the obvious issues with the other "boolean" values, this is more in line with the YAML v1.2.0 specification revision.
* **Numbers are scalars.** Technically speaking, everything is a scalar, but numbers do not have their own explicit type. Instead, they are parsed as string scalars which can then be converted to the desired integer/float/decimal/bigint/etc. type by the end user.
* **Absolutely NO flow nodes.** JSON-style mappings and lists (also known as flow nodes) are not allowed at all. This was initially not allowed in the original implementation, however, discussions to allow flow nodes are/were ongoing. No such considerations will be made in this implementation.
* **No tags.** Only data types defined in this specification are handled. Other data types, like binary or bytes are to be converted manually by the end user.
* **No anchors or references.**

## 3. Differentiation

While the original strictyaml implementation has served as a useful guideline for strict YAML, it lacked several core ### that --

## 4. Data Types

This section will cover the different data types and structures

## 5. Other Constructs

TODO.

## 6. Implementation

TODO.

## 7. Index
