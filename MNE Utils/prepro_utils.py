"""
This script contains several preprocessing utilities for neural data, including:

    - filt_toward_stim(): separates stim epoch into pre-/post-data and applies non-causal 
        filter in band of interest towards stimulation artifact.
    - select_BLAES_electrodes(): ...

Justin Campbell (justin.campbell@hsc.utah.edu)
06/21/23
"""

def select_BLAES_macros(chanLabels):    
        
    # Sometimes in BCI2000
    miscLabels = ['GND', 'PD', 'Sync', 'EMPTY', 'REF', 'EKG', 'chan', '_']
    DCChans = [s for s in chanLabels if s.startswith('DC')]
    
    # Defined per EEG montage
    EEGLabels = ['FP1', 'Fp1', 'AF3', 'F3', 'F7', 'F9', 'FC5', 'FC1', 'FP2', 'Fp2', 'AF4', 'F4', 'F8', 'F10', 'FC6', 'FC2', 'T7', 'C3', 'CP5', 'CP1', 'P3', 'P7', 'PO3', 'PO7', 'T8', 'C4', 'CP6', 'CP2', 'P4', 'P8', 'PO4', 'PO8', 'O1', 'O2', 'A1', 'A2', 'FZ', 'CZ', 'PZ', 'FPZ', 'OZ', 'Cz', 'Fz', 'Pz', 'Oz']
    
    # Check for alternatve WashU naming convention
    NameType = []
    for i in range(len(chanLabels)):
        if "L" in chanLabels[i] or "R" in chanLabels[i]:
            NameType.append(1)
        else:
            NameType.append(0)        
    if (sum(NameType) / len(NameType)) < 0.5:
        EEGLabels = [s.lower() for s in EEGLabels]
        EEGLabels = EEGLabels = ['Fp1', 'Fp2', 'CZ', 'Cz', 'FPZ', 'FZ', 'Fz', 'PZ', 'Pz', 'OZ', 'Oz', 'T7', 'T8']

    # Separate non-macro labels
    EEGChans = [s for s in chanLabels if any(xs == s for xs in EEGLabels)]      # EEG channels
    miscChans = [s for s in chanLabels if any(xs in s for xs in miscLabels)]    # misc BCI2000 channels
    microChans = [s for s in chanLabels if 'm' in s]                            # microelectrode channels
    specialChans = EEGChans + microChans + miscChans + DCChans                  # remove all of the above

    # Grab indices of channels to keep
    keepChanIdxs = [i for i, s in enumerate(chanLabels) if s not in specialChans]

    return keepChanIdxs


def create_bipolar_montage(macroLabels, display = False):
    import re
    import numpy as np
    
    # Remove all numbers from channel labels
    uniqueLabels = np.unique([re.sub(r'\d+', '', chan) for chan in macroLabels])

    # Create separate list for channel labels with matching prefix in uniqueLeads
    anodes = []
    cathodes = []
    for prefix in uniqueLabels:
        leads = [chan for chan in macroLabels if prefix in chan]
        
        # Updated 1/24 to fix issue with re-referencing channels at 9-10
        for x in range(len(leads)):
            if x < len(leads)-1:
                if int(re.sub(r'\D', '', leads[x+1])) - int(re.sub(r'\D', '', leads[x])) == 1:
                    anodes.append(leads[x])
                    cathodes.append(leads[x+1])
                
    # Display bipolar montage
    if display == True:
        for i in range(len(anodes)):
            print('{x} - {y}'.format(x = anodes[i], y = cathodes[i]))

    return anodes, cathodes