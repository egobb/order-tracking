-- Clean tables
TRUNCATE TABLE tracking_events RESTART IDENTITY CASCADE;
TRUNCATE TABLE orders CASCADE;

-- Insert demo orders
INSERT INTO orders (id, created_at, delivered_at, last_status, updated_at) VALUES
  ('order-001', now() - interval '5 days', now() - interval '4 days', 'DELIVERED', now() - interval '4 days'),
  ('order-002', now() - interval '4 days', NULL, 'OUT_FOR_DELIVERY', now() - interval '2 hours'),
  ('order-003', now() - interval '3 days', NULL, 'DELIVERY_ISSUE', now() - interval '1 day'),
  ('order-004', now() - interval '2 days', now() - interval '1 day', 'DELIVERED', now() - interval '1 day'),
  ('order-005', now() - interval '36 hours', NULL, 'PICKED_UP_AT_WAREHOUSE', now() - interval '20 hours'),
  ('order-006', now() - interval '30 hours', now() - interval '20 hours', 'DELIVERED', now() - interval '20 hours'),
  ('order-007', now() - interval '24 hours', NULL, 'OUT_FOR_DELIVERY', now() - interval '2 hours'),
  ('order-008', now() - interval '20 hours', NULL, 'DELIVERY_ISSUE', now() - interval '3 hours'),
  ('order-009', now() - interval '18 hours', NULL, 'PICKED_UP_AT_WAREHOUSE', now() - interval '10 hours'),
  ('order-010', now() - interval '15 hours', now() - interval '6 hours', 'DELIVERED', now() - interval '6 hours');

-- Insert tracking events (valid transitions only)
INSERT INTO tracking_events (event_ts, ingested_at, order_id, status) VALUES
  -- order-001: complete delivery
  (now() - interval '5 days', now() - interval '5 days', 'order-001', 'PICKED_UP_AT_WAREHOUSE'),
  (now() - interval '4 days 12 hours', now() - interval '4 days 12 hours', 'order-001', 'OUT_FOR_DELIVERY'),
  (now() - interval '4 days', now() - interval '4 days', 'order-001', 'DELIVERED'),

  -- order-002: in delivery
  (now() - interval '4 days', now() - interval '4 days', 'order-002', 'PICKED_UP_AT_WAREHOUSE'),
  (now() - interval '2 days', now() - interval '2 days', 'order-002', 'OUT_FOR_DELIVERY'),

  -- order-003: stuck in delivery issue
  (now() - interval '3 days', now() - interval '3 days', 'order-003', 'PICKED_UP_AT_WAREHOUSE'),
  (now() - interval '2 days 12 hours', now() - interval '2 days 12 hours', 'order-003', 'OUT_FOR_DELIVERY'),
  (now() - interval '1 day', now() - interval '1 day', 'order-003', 'DELIVERY_ISSUE'),

  -- order-004: delivered after issue
  (now() - interval '2 days', now() - interval '2 days', 'order-004', 'PICKED_UP_AT_WAREHOUSE'),
  (now() - interval '1 day 18 hours', now() - interval '1 day 18 hours', 'order-004', 'OUT_FOR_DELIVERY'),
  (now() - interval '1 day 12 hours', now() - interval '1 day 12 hours', 'order-004', 'DELIVERY_ISSUE'),
  (now() - interval '1 day 6 hours', now() - interval '1 day 6 hours', 'order-004', 'OUT_FOR_DELIVERY'),
  (now() - interval '1 day', now() - interval '1 day', 'order-004', 'DELIVERED'),

  -- order-005: only picked up
  (now() - interval '36 hours', now() - interval '36 hours', 'order-005', 'PICKED_UP_AT_WAREHOUSE'),

  -- order-006: straight delivery
  (now() - interval '30 hours', now() - interval '30 hours', 'order-006', 'PICKED_UP_AT_WAREHOUSE'),
  (now() - interval '25 hours', now() - interval '25 hours', 'order-006', 'OUT_FOR_DELIVERY'),
  (now() - interval '20 hours', now() - interval '20 hours', 'order-006', 'DELIVERED'),

  -- order-007: in delivery
  (now() - interval '24 hours', now() - interval '24 hours', 'order-007', 'PICKED_UP_AT_WAREHOUSE'),
  (now() - interval '12 hours', now() - interval '12 hours', 'order-007', 'OUT_FOR_DELIVERY'),

  -- order-008: issue
  (now() - interval '20 hours', now() - interval '20 hours', 'order-008', 'PICKED_UP_AT_WAREHOUSE'),
  (now() - interval '10 hours', now() - interval '10 hours', 'order-008', 'OUT_FOR_DELIVERY'),
  (now() - interval '3 hours', now() - interval '3 hours', 'order-008', 'DELIVERY_ISSUE'),

  -- order-009: only picked up
  (now() - interval '18 hours', now() - interval '18 hours', 'order-009', 'PICKED_UP_AT_WAREHOUSE'),

  -- order-010: delivered
  (now() - interval '15 hours', now() - interval '15 hours', 'order-010', 'PICKED_UP_AT_WAREHOUSE'),
  (now() - interval '10 hours', now() - interval '10 hours', 'order-010', 'OUT_FOR_DELIVERY'),
  (now() - interval '6 hours', now() - interval '6 hours', 'order-010', 'DELIVERED');
