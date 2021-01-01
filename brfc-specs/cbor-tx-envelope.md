# CBOR Tx Envelope specification

Standard for serialising a CBOR payload, ensuring consistency when signing the payload.

| BRFC           | Title            | Author(s) | Version |
| -------------- | ---------------- | --------- | ------- |
| `5b82a2ed7b16` | CBOR Tx Envelope | Libs      | 1       |

## Overview

When sharing data objects, inconsistencies between implementations can cause changes to the data object (for example, key order) which would cause signature verification to fail.

The [JSON Envelope](https://github.com/bitcoin-sv-specs/brfc-misc/tree/master/jsonenvelope) BRFC described a technique to ensure consitency of the data being signed by encoding the JSON payload inside a parent JSON object (the envelope). This specification proposes using the same technique applied to CBOR ([Concise Binary Object Representation](http://cbor.io)) encoded payloads.

As CBOR is a concise binary-friendly format, it offers a highly efficient way of encapsulating public keys, signatures and other binary values. CBOR can also be used in streaming applications.

## Envelope data definition

The following CBOR structure is described using CDDL ([Concise Data Definition Language](https://tools.ietf.org/html/rfc8610)).

```cddl
Envelope = {
  payload: bytes,
  ? pubkey: bytes,
  ? signature: bytes
}
```

The `Envelope` type is a map which must contain a `payload` field, and may contain `pubkey` and `signature` fields. The value of the `payload` field must be a CBOR-encoded binary. If present, the `pubkey` field must be a Bitcoin public key binary, and the `signature` field must be an ECDSA signature.

## Signing algorithm

An ECDSA signature is created by calculating the `sha256` hash of the `payload` binary, and signing the hash with a Bitcoin private key. The resulting signature and the private key's corresponding public key are included in the `Envelope` data item.

The recieving end can verify the signature by calculating the `sha256` hash of the `payload` binary, and verifying the `signature` against the hash, using the `pubkey`.

## CBOR data format

There are several alternative binary data serialisation formats, such as [Protobuf](https://developers.google.com/protocol-buffers), [MessagePack](https://msgpack.org/index.html) and [BSON](http://bsonspec.org).

[CBOR](http://cbor.io) was chosen because it has a well defined [specification](https://www.rfc-editor.org/rfc/rfc8949.html) with [implementations](http://cbor.io/impls.html) in many languages, and strikes the right balance of simplicity and flexibility. CBOR is largely isomorphic to JSON, plus supports byte arrays. Which is exactly what is needed.

## HTTP requests

A valid HTTP request or response must contain the following:

* **Headers**:
  * **Content-Type**: Must be `"application/cbor"` or can be any media type with the +suffix `"+cbor"`, for example: `"xxx/yyy+cbor"`.
* **Body**: The `Envelope` data must be CBOR-encoded.

## Streaming applications

In a streaming application, a data stream may be composed of a sequence of CBOR-encoded `Envelope` data items concatenated back-to-back. The receiving end will buffer data until one or more complete `Envelope` data items can be decoded. Any remaining data is buffered until it too can be decoded.

## Implementations

The following implementations of this BRFC are available:

* [Txpost](https://github.com/libitx/txpost/issues) - Elixir
* Coming soon - JavaScript

## Comments

This spec is released as an RFC (request for comment) as part of the public review process. Any comments, criticisms or suggestions should be directed toward the Txpost repository [issues page](https://github.com/libitx/txpost/issues).