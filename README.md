# Lab. 7: Motion analysis

🚧 Repository under construction.

Assignment Rules:

This assignment is about motion analysis and is composed of two parts:

- The first part is mandatory and can give you a max grade of **80/100**
- The second part is optional and can give you **20 extra points**
- Please read carefully the following guidelines

## PART 1 Mandatory (max grade 80/100)

The goal of this part is the analysis and comparison of change detection algorithms and optical flow. The following is required:

### 1) Change detection comparison (fixed background vs running average)

Produce a Matlab function `compareCDAlgo` starting from [THIS TEMPLATE](https://2025.aulaweb.unige.it/pluginfile.php/224960/mod_assign/intro/compareCDAlgo.m) and use it to compare on [THIS VIDEO](https://www.dropbox.com/scl/fi/379tvyv6b0zbqejeu477g/luce_vp.mp4?rlkey=k1g73uddu5g1ygip2dbm17y6m&dl=0) the output of change detection by using:

- A fixed background (a single frame or the average of the first **N** frames)
- A running average

### 2) Change detection vs optical flow

Produce a Matlab function `compareCDOF` starting from [THIS TEMPLATE](https://2025.aulaweb.unige.it/pluginfile.php/224960/mod_assign/intro/compareCDOF.m) and use it to compare on [THIS VIDEO](https://www.dropbox.com/scl/fi/fekgrwwa507hzlx8ro0l1/tennis.mp4?rlkey=5yypbww8pte7xs6jwkno8619v&dl=0) the output of:

- Change detection with running average
- Optical flow (auxiliary function [HERE](https://2025.aulaweb.unige.it/pluginfile.php/224960/mod_assign/intro/convertToMagDir.m))

## PART 2 Optional (Further 20 points)

The goal of this part is to implement a simple tracker of a fixed target (manually selected) starting from [THIS TEMPLATE](https://2025.aulaweb.unige.it/pluginfile.php/224960/mod_assign/intro/segmentAndTrack.m) and using [THIS VIDEO](https://www.dropbox.com/scl/fi/jrm1gql3gwaxgjj140cbz/DibrisHall.mp4?rlkey=k7dwli0lzbszxh95qmi22viz7&dl=0)

## What you need to submit

- All the code, appropriately commented

### IMPORTANT: remember to

- Convert to gray-level images before processing
- Convert to **DOUBLE** the images before the differencing operation (otherwise you loose the negative values)
- Convert to **UINT8** the images before the visualization

Use the following lines to force Matlab to close the output window:

```matlab
% Check if the user has closed the figure
if ~isvalid(hFigure)
    disp('Playback interrupted by user.');
    break;
end
