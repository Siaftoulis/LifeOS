/// Preset configurations for Poweramp Equalizer
class EqPreset {
  final String name;
  final List<double> bands; // 10 bands from 31Hz to 16kHz (-12.0 to +12.0 dB)
  final double preamp;
  final double bassBoost;
  final double trebleBoost;

  const EqPreset({
    required this.name,
    required this.bands,
    this.preamp = 0.0,
    this.bassBoost = 0.0,
    this.trebleBoost = 0.0,
  });
}

const List<String> kEqBandFrequencies = [
  '31',
  '62',
  '125',
  '250',
  '500',
  '1k',
  '2k',
  '4k',
  '8k',
  '16k',
];

const List<EqPreset> kEqDefaultPresets = [
  EqPreset(
    name: 'Flat',
    bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    preamp: 0.0,
    bassBoost: 0.0,
    trebleBoost: 0.0,
  ),
  EqPreset(
    name: 'Bass Boost / EDM',
    bands: [8.5, 7.0, 5.0, 2.0, 0.0, -1.0, 1.5, 3.0, 5.5, 6.0],
    preamp: -2.0,
    bassBoost: 0.7,
    trebleBoost: 0.2,
  ),
  EqPreset(
    name: 'Rock & Metal',
    bands: [5.0, 3.5, 2.0, 0.5, -1.0, 1.0, 3.0, 5.0, 6.5, 7.0],
    preamp: -1.5,
    bassBoost: 0.4,
    trebleBoost: 0.4,
  ),
  EqPreset(
    name: 'Vocal & Clarity',
    bands: [-2.0, -1.0, 0.5, 2.0, 4.5, 5.0, 4.0, 2.5, 1.0, 0.0],
    preamp: 0.0,
    bassBoost: 0.1,
    trebleBoost: 0.3,
  ),
  EqPreset(
    name: 'Audiophile Reference',
    bands: [1.5, 1.0, 0.5, 0.0, 0.0, 0.5, 1.0, 1.5, 2.0, 2.5],
    preamp: 0.0,
    bassBoost: 0.15,
    trebleBoost: 0.15,
  ),
  EqPreset(
    name: 'Electronic / Club',
    bands: [7.0, 5.5, 3.0, 0.0, -1.5, 2.0, 4.0, 6.0, 7.0, 7.5],
    preamp: -2.0,
    bassBoost: 0.6,
    trebleBoost: 0.5,
  ),
];
