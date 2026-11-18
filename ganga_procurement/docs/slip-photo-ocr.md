# Slip photo OCR: editable field suggestions

## Goal

Help a weighment worker take a photo of a Ganga Agri Genetics weighment slip and use the reading as a draft aid. The worker checks the slip and confirms every value before saving a weighment.

## First milestone implemented

- The Android app runs OCR locally with Tesseract and English + Telugu language data.
- It displays recognized text alongside the original slip photo and offers a **Fill entries** button.
- Labelled farmer name, mobile, crop, bag count, rate, and clearly numbered weight rows can be suggested into the existing editable form.
- Farmer name is required to save a farmer; mobile is optional. Existing farmer details can be edited before saving.
- The user can choose a new photo from the gallery, or remove the attached photo and replace it.
- Suggested values are never saved automatically. The worker checks and edits them before saving.
- OCR failures leave the normal manual entry flow available.
- The photo and OCR text are not sent to a web service. OCR text is temporary screen state; the existing weighment save continues to store the chosen photo.

## What comes next

Extraction is deliberately conservative because the OCR service returns plain text rather than table coordinates. It accepts clearly labelled fields and numbered weight rows only; handwriting, Telugu labels, merged rows, and uncertain counts may not be recognized. Missing values stay blank and must be entered or corrected by the worker. The app does not claim that the sample handwriting is reliably machine-readable yet.

Mobile is optional on the slip and in the farmer form. OCR does not auto-select or save a farmer; the worker can match the mobile/name to a saved farmer or explicitly save the suggested farmer after review.

## Proposed field review

1. Extend extraction only when a field's layout can be identified reliably; all suggestions remain reviewable.
2. Check the count of recognized weights against the stated number of bags. Missing weights remain empty for manual entry.
3. Keep the original photo attached to the saved weighment for audit.
4. Preserve the existing rate, deductions, interest, and payable calculation rules.

## Sample coverage

The five local examples include four slips with handwritten bag weights and one blank template. One filled slip has an unclear bag count. The samples are kept in H:\Seed business\App\sample_slips_for_ocr and must stay out of Git because they contain personal information.

## Open-source components

- Flutter package tesseract_ocr 0.6.0 (BSD-3-Clause wrapper).
- Tesseract OCR engine (Apache-2.0).
- eng and tel trained data from the official tesseract-ocr/tessdata_fast repository (Apache-2.0).

All recognition in this milestone runs on the Android device. No account, subscription, or network connection is needed for OCR after installation.
