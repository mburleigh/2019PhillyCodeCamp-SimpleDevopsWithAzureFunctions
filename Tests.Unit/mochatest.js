var assert = require('assert');

// the unit under test
var greetings = require('../Src/Common/greetings')

describe('Greetings', function() {
  describe('TxAgs', function() {
    it('returns the correct value', function() {
      assert.equal(greetings.TxAgs(), 'Howdy')
    });
  });

  describe('Klingon', function() {
    it('returns the correct value', function() {
      assert.equal(greetings.Klingon(), 'Qapla')
    });
  });

  describe('Jedi', function() {
    it('returns the correct value', function() {
      assert.equal(greetings.Jedi(), 'May the Force be with you')
    });
  });
});