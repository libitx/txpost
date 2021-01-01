# CBOR Tx Payload specification

Concise binary serialisation structure for sending and receiving Bitcoin transactions and artibrary data parameters over HTTP.

| BRFC           | Title           | Author(s) | Version |
| -------------- | --------------- | --------- | ------- |
| `c9a2975b3d19` | CBOR Tx Payload | Libs      | 1       |

## Overview

Applications that send and receive Bitcoin transactions over HTTP often use text serialisation formats such as JSON. When binary data is hex encoded it adds a 100% bandwidth overhead. Even with gzip compression the overhead is around 25%.

This specification proposes using CBOR ([Concise Binary Object Representation](http://cbor.io)) to encode a simple and flexible data structure that offers the following benefits:

* A simple data model as familiar as JSON
* Efficient, binary-friendly format with minimal data overhead
* Simple schema for transferring Bitcoin transactions alongside arbitrary data parameters and meta data
* Multiple transactions can be sent in a single request
* Can be used in streaming applications

## Payload data definition

The following CBOR structure is described using CDDL ([Concise Data Definition Language](https://tools.ietf.org/html/rfc8610)).

```cddl
Payload = {
  data: Data / [* Data],
  ? meta: { * text => any },
}

Data = {
  rawtx: binary,
  * text => any
}
```

The `Payload` type is a map which must contain a `data` field and may contain a `meta` field. The value of the `data` field must be a `Data` map or array of `Data` maps. If present, the the `meta` field must be a map which can contain any arbitrary key/value parameters.

The `Data` type is a map which must contain a `rawtx` binary value and any other optional arbitrary key/value parameters.

The `Payload` `data` and `meta` fields provide namespaces for including arbitrary data alongside the transaction. Use of these fields will be application specific, but the following distinction is advised:

* The `data` namespace should be used for including supplementary data parameters that can be seen as related to the resource the transaction relates to. For example, if the transaction contains a hash of a file, but not the file itself, the file data could also be sent to the application alongside the transaction in the `data `map.
* The `meta` namespace should be used for including arbitrary data useful to the application, but unrelated to the resource the transaction relates to. For example, the meta map could include routing information or authentication parameters.

## CBOR data format

There are several alternative binary data serialisation formats, such as [Protobuf](https://developers.google.com/protocol-buffers), [MessagePack](https://msgpack.org/index.html) and [BSON](http://bsonspec.org).

[CBOR](http://cbor.io) was chosen because it has a well defined [specification](https://www.rfc-editor.org/rfc/rfc8949.html) with [implementations](http://cbor.io/impls.html) in many languages, and strikes the right balance of simplicity and flexibility. CBOR is largely isomorphic to JSON, plus supports byte arrays. Which is exactly what is needed.

## HTTP requests

A valid HTTP request or response must contain the following:

* **Headers**:
  * **Content-Type**: Must be `"application/cbor"` or can be any media type with the +suffix `"+cbor"`, for example: `"xxx/yyy+cbor"`.
* **Body**: The `Payload` data must be CBOR-encoded.

## Streaming applications

In a streaming application, a data stream may be composed of a sequence of CBOR-encoded `Payload` data items concatenated back-to-back. The receiving end will buffer data until one or more complete `Payload` data items can be decoded. Any remaining data is buffered until it too can be decoded.

## Implementations

The following implementations of this BRFC are available:

* [Txpost](https://github.com/libitx/txpost/issues) - Elixir
* Coming soon - JavaScript

## Comments

This spec is released as an RFC (request for comment) as part of the public review process. Any comments, criticisms or suggestions should be directed toward the Txpost repository [issues page](https://github.com/libitx/txpost/issues).