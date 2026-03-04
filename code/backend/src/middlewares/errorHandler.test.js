const test = require('node:test');
const assert = require('node:assert/strict');

const ApiError = require('../utils/ApiError');
const { errorHandler } = require('./errorHandler');

function createRes(headersSent = false) {
  return {
    headersSent,
    _status: null,
    _json: null,
    _setCalls: [],
    set(key, value) {
      this._setCalls.push([key, value]);
      return this;
    },
    status(code) {
      this._status = code;
      return this;
    },
    json(payload) {
      this._json = payload;
      return this;
    },
  };
}

test('errorHandler: returns ApiError status and message', () => {
  const prev = process.env.NODE_ENV;
  process.env.NODE_ENV = 'production';

  const res = createRes(false);
  errorHandler(new ApiError(404, 'Booking not found'), {}, res, () => {});

  assert.equal(res._status, 404);
  assert.deepEqual(res._json, {
    success: false,
    message: 'Booking not found',
    data: null,
  });
  assert.deepEqual(res._setCalls[0], ['Content-Type', 'application/json; charset=utf-8']);

  process.env.NODE_ENV = prev;
});

test('errorHandler: maps unknown error to generic 500 response', () => {
  const prev = process.env.NODE_ENV;
  process.env.NODE_ENV = 'production';

  const res = createRes(false);
  errorHandler(new Error('database down'), {}, res, () => {});

  assert.equal(res._status, 500);
  assert.deepEqual(res._json, {
    success: false,
    message: 'เกิดข้อผิดพลาดภายในระบบ กรุณาลองใหม่ภายหลัง',
    data: null,
  });

  process.env.NODE_ENV = prev;
});

test('errorHandler: does not set content-type when headers were already sent', () => {
  const prev = process.env.NODE_ENV;
  process.env.NODE_ENV = 'production';

  const res = createRes(true);
  errorHandler(new ApiError(403, 'Forbidden'), {}, res, () => {});

  assert.equal(res._status, 403);
  assert.equal(res._setCalls.length, 0);
  assert.deepEqual(res._json, {
    success: false,
    message: 'Forbidden',
    data: null,
  });

  process.env.NODE_ENV = prev;
});
