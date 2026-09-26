# AquaVol mathematical reference

This package is an independent reference for the AquaVol pricing specification.
It uses only the Python standard library and is not part of the live transaction
path.

Run the tests from the repository root:

```bash
PYTHONPATH=python python3 -m unittest discover -s python/tests -v
```

Regenerate the canonical vector document:

```bash
PYTHONPATH=python python3 -m aquavol_math.generate_vectors
```

The generator prints JSON to standard output. Compare it with
`test/vectors/black_scholes-v1.json`; do not replace the committed vector file
without reviewing the numerical change and updating its schema or model
version when appropriate.

