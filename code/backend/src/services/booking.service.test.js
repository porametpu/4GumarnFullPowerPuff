const test = require('node:test');
const assert = require('node:assert/strict');

const ApiError = require('../utils/ApiError');
const bookingService = require('./booking.service');

const { resolveExtraLuggage } = bookingService.__testables;

test('resolveExtraLuggage: returns default when extra luggage is not selected', () => {
  const route = { allowExtraLuggage: true, maxExtraLuggageType: 'EXTRA_LARGE' };
  const result = resolveExtraLuggage(route, { extraLuggageSelected: false });

  assert.deepEqual(result, {
    extraLuggageSelected: false,
    extraLuggageType: null,
    extraLuggageFee: 0,
  });
});

test('resolveExtraLuggage: throws 400 when route does not allow extra luggage', () => {
  const route = { allowExtraLuggage: false, maxExtraLuggageType: null };

  assert.throws(
    () => resolveExtraLuggage(route, { extraLuggageSelected: true, extraLuggageType: 'MEDIUM' }),
    (err) => err instanceof ApiError && err.statusCode === 400
  );
});

test('resolveExtraLuggage: throws 400 when luggage type is invalid', () => {
  const route = { allowExtraLuggage: true, maxExtraLuggageType: 'EXTRA_LARGE' };

  assert.throws(
    () => resolveExtraLuggage(route, { extraLuggageSelected: true, extraLuggageType: 'INVALID' }),
    (err) => err instanceof ApiError && err.statusCode === 400
  );
});

test('resolveExtraLuggage: throws 400 when requested type is above route limit', () => {
  const route = { allowExtraLuggage: true, maxExtraLuggageType: 'MEDIUM' };

  assert.throws(
    () => resolveExtraLuggage(route, { extraLuggageSelected: true, extraLuggageType: 'LARGE' }),
    (err) => err instanceof ApiError && err.statusCode === 400
  );
});

test('resolveExtraLuggage: computes correct fee for allowed type', () => {
  const route = { allowExtraLuggage: true, maxExtraLuggageType: 'LARGE' };
  const result = resolveExtraLuggage(route, {
    extraLuggageSelected: true,
    extraLuggageType: 'LARGE',
  });

  assert.deepEqual(result, {
    extraLuggageSelected: true,
    extraLuggageType: 'LARGE',
    extraLuggageFee: 100,
  });
});
