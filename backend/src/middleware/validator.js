/**
 * Request Validation Middleware for TravelTales Backend APIs
 */

function isValidDateString(str) {
  if (typeof str !== 'string' || !str.trim()) return false;
  const time = Date.parse(str);
  return !isNaN(time);
}

const validateCreateTrip = (req, res, next) => {
  const { title, destination, startDate, endDate, budget } = req.body;

  if (!title || typeof title !== 'string' || !title.trim()) {
    return res.status(400).json({
      success: false,
      message: 'Title is required and must be a non-empty string.',
    });
  }

  if (!destination || typeof destination !== 'string' || !destination.trim()) {
    return res.status(400).json({
      success: false,
      message: 'Destination is required and must be a non-empty string.',
    });
  }

  if (!startDate || !isValidDateString(startDate)) {
    return res.status(400).json({
      success: false,
      message: 'A valid startDate in ISO format is required.',
    });
  }

  if (!endDate || !isValidDateString(endDate)) {
    return res.status(400).json({
      success: false,
      message: 'A valid endDate in ISO format is required.',
    });
  }

  if (new Date(endDate).getTime() < new Date(startDate).getTime()) {
    return res.status(400).json({
      success: false,
      message: 'endDate must be on or after startDate.',
    });
  }

  if (budget !== undefined) {
    const num = Number(budget);
    if (isNaN(num) || num < 0) {
      return res.status(400).json({
        success: false,
        message: 'Budget must be a non-negative number.',
      });
    }
  }

  next();
};

const validateUpdateTrip = (req, res, next) => {
  const { title, destination, startDate, endDate, budget } = req.body;

  if (title !== undefined && (typeof title !== 'string' || !title.trim())) {
    return res.status(400).json({
      success: false,
      message: 'Title must be a non-empty string.',
    });
  }

  if (destination !== undefined && (typeof destination !== 'string' || !destination.trim())) {
    return res.status(400).json({
      success: false,
      message: 'Destination must be a non-empty string.',
    });
  }

  if (startDate !== undefined && !isValidDateString(startDate)) {
    return res.status(400).json({
      success: false,
      message: 'startDate must be a valid ISO date string.',
    });
  }

  if (endDate !== undefined && !isValidDateString(endDate)) {
    return res.status(400).json({
      success: false,
      message: 'endDate must be a valid ISO date string.',
    });
  }

  if (startDate && endDate && new Date(endDate).getTime() < new Date(startDate).getTime()) {
    return res.status(400).json({
      success: false,
      message: 'endDate must be on or after startDate.',
    });
  }

  if (budget !== undefined) {
    const num = Number(budget);
    if (isNaN(num) || num < 0) {
      return res.status(400).json({
        success: false,
        message: 'Budget must be a non-negative number.',
      });
    }
  }

  next();
};

const validateCreateActivity = (req, res, next) => {
  const tripId = req.params.tripId || req.body.tripId;
  const { dayNumber, date, timeString, title, location, category } = req.body;

  if (!tripId || typeof tripId !== 'string' || !tripId.trim()) {
    return res.status(400).json({
      success: false,
      message: 'tripId is required.',
    });
  }

  const dayNum = Number(dayNumber);
  if (dayNumber === undefined || !Number.isInteger(dayNum) || dayNum < 1) {
    return res.status(400).json({
      success: false,
      message: 'dayNumber must be an integer >= 1.',
    });
  }

  if (!date || !isValidDateString(date)) {
    return res.status(400).json({
      success: false,
      message: 'A valid date in ISO format is required.',
    });
  }

  if (!timeString || typeof timeString !== 'string' || !timeString.trim()) {
    return res.status(400).json({
      success: false,
      message: 'timeString is required (e.g. "09:00 AM" or "14:00").',
    });
  }

  if (!title || typeof title !== 'string' || !title.trim()) {
    return res.status(400).json({
      success: false,
      message: 'title is required and must be a non-empty string.',
    });
  }

  if (!location || typeof location !== 'string' || !location.trim()) {
    return res.status(400).json({
      success: false,
      message: 'location is required.',
    });
  }

  if (!category || typeof category !== 'string' || !category.trim()) {
    return res.status(400).json({
      success: false,
      message: 'category is required.',
    });
  }

  next();
};

const validateUpdateActivity = (req, res, next) => {
  const { dayNumber, date, timeString, title, location, category } = req.body;

  if (dayNumber !== undefined) {
    const num = Number(dayNumber);
    if (!Number.isInteger(num) || num < 1) {
      return res.status(400).json({
        success: false,
        message: 'dayNumber must be an integer >= 1.',
      });
    }
  }

  if (date !== undefined && !isValidDateString(date)) {
    return res.status(400).json({
      success: false,
      message: 'date must be a valid ISO date string.',
    });
  }

  if (timeString !== undefined && (typeof timeString !== 'string' || !timeString.trim())) {
    return res.status(400).json({
      success: false,
      message: 'timeString must be a non-empty string.',
    });
  }

  if (title !== undefined && (typeof title !== 'string' || !title.trim())) {
    return res.status(400).json({
      success: false,
      message: 'title must be a non-empty string.',
    });
  }

  if (location !== undefined && (typeof location !== 'string' || !location.trim())) {
    return res.status(400).json({
      success: false,
      message: 'location must be a non-empty string.',
    });
  }

  if (category !== undefined && (typeof category !== 'string' || !category.trim())) {
    return res.status(400).json({
      success: false,
      message: 'category must be a non-empty string.',
    });
  }

  next();
};

const validateCreateExpense = (req, res, next) => {
  const tripId = req.params.tripId || req.body.tripId;
  const { title, amount, category, date } = req.body;

  if (!tripId || typeof tripId !== 'string' || !tripId.trim()) {
    return res.status(400).json({
      success: false,
      message: 'tripId is required.',
    });
  }

  if (!title || typeof title !== 'string' || !title.trim()) {
    return res.status(400).json({
      success: false,
      message: 'title is required and must be a non-empty string.',
    });
  }

  if (amount === undefined || amount === null) {
    return res.status(400).json({
      success: false,
      message: 'amount is required.',
    });
  }

  const numAmount = Number(amount);
  if (isNaN(numAmount) || numAmount <= 0) {
    return res.status(400).json({
      success: false,
      message: 'amount must be a positive number greater than 0.',
    });
  }

  if (!category || typeof category !== 'string' || !category.trim()) {
    return res.status(400).json({
      success: false,
      message: 'category is required.',
    });
  }

  if (!date || !isValidDateString(date)) {
    return res.status(400).json({
      success: false,
      message: 'A valid date in ISO format is required.',
    });
  }

  next();
};

const validateUpdateExpense = (req, res, next) => {
  const { title, amount, category, date } = req.body;

  if (title !== undefined && (typeof title !== 'string' || !title.trim())) {
    return res.status(400).json({
      success: false,
      message: 'title must be a non-empty string.',
    });
  }

  if (amount !== undefined) {
    const numAmount = Number(amount);
    if (isNaN(numAmount) || numAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'amount must be a positive number greater than 0.',
      });
    }
  }

  if (category !== undefined && (typeof category !== 'string' || !category.trim())) {
    return res.status(400).json({
      success: false,
      message: 'category must be a non-empty string.',
    });
  }

  if (date !== undefined && !isValidDateString(date)) {
    return res.status(400).json({
      success: false,
      message: 'date must be a valid ISO date string.',
    });
  }

  next();
};

const validateId = (paramName = 'id') => (req, res, next) => {
  const idVal = req.params[paramName];
  if (!idVal || typeof idVal !== 'string' || !idVal.trim()) {
    return res.status(400).json({
      success: false,
      message: `Invalid or missing ${paramName} parameter.`,
    });
  }
  next();
};

module.exports = {
  validateCreateTrip,
  validateUpdateTrip,
  validateCreateActivity,
  validateUpdateActivity,
  validateCreateExpense,
  validateUpdateExpense,
  validateId,
};
