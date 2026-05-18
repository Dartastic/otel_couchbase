// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_couchbase/otel_couchbase.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_couchbase-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('KV upsert records CLIENT span', () async {
    await tracedCouchbaseKv<String>(
      operation: 'upsert',
      bucket: 'travel-sample',
      docId: 'airline_42',
      scope: '_default',
      collection: 'airlines',
      invoke: () async => 'ok',
    );
    final a = attrsOf(
      spans.findSpanByName('couchbase upsert travel-sample')!,
    );
    expect(a['db.system'], 'couchbase');
    expect(a['db.operation'], 'upsert');
    expect(a['db.name'], 'travel-sample');
    expect(a['couchbase.bucket'], 'travel-sample');
    expect(a['couchbase.document.id'], 'airline_42');
    expect(a['couchbase.scope'], '_default');
    expect(a['couchbase.collection'], 'airlines');
  });

  test('N1QL records db.statement', () async {
    await tracedCouchbaseQuery<String>(
      statement: 'SELECT * FROM `travel-sample` LIMIT 5',
      bucket: 'travel-sample',
      consistency: 'request_plus',
      invoke: () async => 'rows',
    );
    final a = attrsOf(spans.findSpanByName('couchbase n1ql query')!);
    expect(a['db.system'], 'couchbase');
    expect(a['db.statement'], 'SELECT * FROM `travel-sample` LIMIT 5');
    expect(a['couchbase.query.consistency'], 'request_plus');
  });

  test('suppression skips spans', () async {
    await runWithoutCouchbaseInstrumentationAsync(() async {
      await tracedCouchbaseKv<String>(
        operation: 'get',
        bucket: 'b',
        docId: 'd',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('couchbase '), isEmpty);
  });
}
