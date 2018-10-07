[![Build Status](https://travis-ci.org/lxcid/ListDiff.svg?branch=master)](https://travis-ci.org/lxcid/ListDiff)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ListDiff.svg)](https://cocoapods.org/pods/ListDiff)

# ListDiff

__ListDiff__ is a Swift port of [IGListKit](https://github.com/Instagram/IGListKit)'s [IGListDiff](https://github.com/Instagram/IGListKit/blob/master/Source/IGListDiff.mm).
It is an implementation of [an algorithm by Paul Heckel](http://dl.acm.org/citation.cfm?id=359467&dl=ACM&coll=DL) that calculates the diff between 2 arrays.

## Motivation

The motivation for this project came from the following [challenge](https://github.com/Instagram/IGListKit/issues/76) which I learnt about it from [Ryan Nystrom](https://twitter.com/_ryannystrom)'s [talk](https://engineers.sg/video/scaling-at-large-lessons-learned-rewriting-instagram-s-feed-ios-conf-sg-2016--1218) at [iOSConf.SG](http://iosconf.sg).

## Getting Started

```bash
swift package generate-xcodeproj
```

## Installation

#### CocoaPods

```ruby
pod 'ListDiff'
```

#### Carthage

```ogdl
github "lxcid/ListDiff" "master"
```

## Usage

```swift
import ListDiff

extension Int : Diffable {
    public var diffIdentifier: AnyHashable {
        return self
    }
}
let o = [0, 1, 2]
let n = [2, 1, 3]
let result = List.diffing(oldArray: o, newArray: n)
// result.hasChanges == true
// result.deletes == IndexSet(integer: 0)
// result.inserts == IndexSet(integer: 2)
// result.moves == [List.MoveIndex(from: 2, to: 0), List.MoveIndex(from: 1, to: 1)]
// result.changeCount == 4
```

## Rationale

During the port, I made several decisions which I would like to rationalize here.

- _Using caseless enum as namespace._ See [Erica Sadun's post here](http://ericasadun.com/2016/07/18/dear-erica-no-case-enums/).
- _No support for index paths._ Decided that this is out of the scope.
- _Stack vs Heap._ AFAIK, Swift does not advocates thinking about stack vs heap allocation model, leaving the optimization decisions to compiler instead. Nevertheless, some of the guideline do favour `struct` more, so only `List.Entry` is a (final) class as we need reference to its instances.

## Alternatives

- [Diff](https://github.com/AndrewSB/Diff) by [Andrew Breckenridge](https://github.com/AndrewSB)
