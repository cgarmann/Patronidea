abstract final class AppConstants {
  static const appName = 'FRUMA';

  // Idea constraints
  static const ideaTitleMaxWords = 15;
  static const ideaBodyMaxWords = 150;
  static const pitchMaxWords = 150;

  // Smart Engine
  static const similarityThreshold = 0.85;

  // Subscription
  static const patronMonthlyProductId = 'patron_monthly_v1';
  static const patronYearlyProductId = 'patron_yearly_v1';
  static const patronMonthlyPriceUsd = 14.99;
  static const patronYearlyPriceUsd = 119.99;
  static const stripePublishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  // Idea price range (USD cents)
  static const ideaMinPrice = 5000; // $50
  static const ideaMaxPrice = 500000; // $5,000

  // Categories
  static const categories = [
    'SaaS',
    'Green Tech',
    'Local Solutions',
    'Technology',
    'Health & Wellness',
    'Education',
    'Entertainment',
    'Sustainability',
    'Finance',
    'Social Impact',
    'Food & Beverage',
    'Fashion & Design',
    'Other',
  ];
}
