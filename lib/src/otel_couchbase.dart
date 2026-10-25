// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_couchbase_suppression.dart';

const _tracerName = 'dartastic_otel_libs_couchbase';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a Couchbase KV op (get/upsert/replace/remove) on a
/// document in a CLIENT span. db.system=couchbase.
Future<T> tracedCouchbaseKv<T>({
  required String operation,
  required String bucket,
  required String docId,
  required Future<T> Function() invoke,
  String? scope,
  String? collection,
}) async {
  if (couchbaseInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'db.system': 'couchbase',
    'db.operation': operation,
    'db.name': bucket,
    'couchbase.bucket': bucket,
    'couchbase.document.id': docId,
  };
  if (scope != null) m['couchbase.scope'] = scope;
  if (collection != null) {
    m['db.collection.name'] = collection;
    m['couchbase.collection'] = collection;
  }

  final span = _tracer().startSpan(
    'couchbase $operation $bucket',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

const _maxStatementLength = 1024;
String _truncate(String s) =>
    s.length <= _maxStatementLength ? s : s.substring(0, _maxStatementLength);

/// Wraps a Couchbase N1QL / SQL++ query in a CLIENT span.
Future<T> tracedCouchbaseQuery<T>({
  required String statement,
  required Future<T> Function() invoke,
  String? bucket,
  String? scope,
  String? collection,
  String? consistency,
}) async {
  if (couchbaseInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'db.system': 'couchbase',
    'db.operation': 'query',
    'db.statement': _truncate(statement),
    'couchbase.query.language': 'N1QL',
  };
  if (bucket != null) m['couchbase.bucket'] = bucket;
  if (scope != null) m['couchbase.scope'] = scope;
  if (collection != null) {
    m['db.collection.name'] = collection;
    m['couchbase.collection'] = collection;
  }
  if (consistency != null) m['couchbase.query.consistency'] = consistency;

  final span = _tracer().startSpan(
    'couchbase n1ql query',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
