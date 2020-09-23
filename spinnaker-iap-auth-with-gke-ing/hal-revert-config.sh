# hal config security api edit --override-base-url /gate
# hal config security ui edit --override-base-url https://spin-deck.mydomaininc.org
hal config security authn iap disable
hal deploy apply
