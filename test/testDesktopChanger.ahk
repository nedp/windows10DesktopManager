#Include %A_ScriptDir%\..\lib\Yunit\Yunit.ahk
#Include %A_ScriptDir%\..\lib\Yunit\StdOut.ahk

#Include %A_ScriptDir%\mocks.ahk
#Include %A_ScriptDir%\globals.ahk

#Include %A_ScriptDir%\..\src\DesktopChanger.ahk

#Warn

ExitApp, % Yunit.Use(YunitStdOut).Test(DesktopChangerTest).didFail
return

class DesktopChangerTest {

    begin(target := "") {
        this.tester := target

        FunctionMocks.reset()
        target.hotMocks := new HotMocks()

        this.tester.desktop := 10
        this.tester.nDesktops := 20

        this.tester.desktopMapper := new Mock(this.tester.hotMocks)
        this.tester.hotMocks.allow(this.tester.desktopMapper, "currentDesktop"
            , this.tester.desktop)
        this.tester.hotMocks.allow(this.tester.desktopMapper, "syncDesktopCount"
            , this.tester.nDesktops)

        this.tester.dwm := new Mock(this.tester.hotMocks
            , {nDesktops: this.tester.nDesktops})

        this.tester.tooltip := new Mock(this.tester.hotMocks
            , {x: 3, y: 4, id: 5})

        FunctionMocks.allow("refocus")
    }

    end() {
        this.tester.hotMocks.assert()
        FunctionMocks.assert()
    }

    givenFewerDesktopsPresent(nDiff) {
        ;; We have nDiff fewer than we want.
        this.tester.hotMocks.allow(this.tester.desktopMapper
            , "syncDesktopCount", this.tester.nDesktops - nDiff)
    }

    givenMoreDesktopsPresent(nDiff) {
        ;; We have nDiff more than we want.
        this.tester.hotMocks.allow(this.tester.desktopMapper
            , "syncDesktopCount" , this.tester.nDesktops + nDiff)
    }

    givenFewerDesktopsWanted(nDiff) {
        ;; We want nDiff fewer than we have.
        this.tester.dwm.nDesktops := this.tester.nDesktops - nDiff
    }

    givenMoreDesktopsWanted(nDiff) {
        ;; We want nDiff more than we have.
        this.tester.dwm.nDesktops := this.tester.nDesktops + nDiff
    }

    expectNoChanges() {
        ;; Read only operations like refocus are ok.
        FunctionMocks.disallow("slowSend")
        FunctionMocks.disallow("quickSend")
    }

    ;; Expect desktops to be added via slowSend at the rightmost desktop.
    expectAddDesktops(count) {
        keys := "i)(\^#|#\^){d\s+" count "}"
        FunctionMocks.expectAtLeast("slowSend")
            .argsLike([ keys
                      , this.MOVE_RIGHT_ARG ])
    }

    ;; Expect desktops to be deleted via slowSend at the rightmost desktop.
    expectRemoveDesktops(count) {
        keys := "i)(\^#|#\^){F4\s+" count "}"
        FunctionMocks.expectAtLeast("slowSend")
            .argsLike([ keys
                      , this.MOVE_RIGHT_ARG ])
    }

    rememberValues() {
        this.rememberedValues := { dwm: this.tester.dwm
                                 , desktopMapper: this.tester.desktopMapper
                                 , tooltip: this.tester.tooltip
                                 , desktop: this.tester.desktop
                                 , nDesktops: this.tester.nDesktops }
    }

    assertSameValues() {
        Yunit.assertEq(this.rememberedValues.dwm, this.tester.dwm)
        Yunit.assertEq(this.rememberedValues.desktopMapper
            , this.tester.desktopMapper)
        Yunit.assertEq(this.rememberedValues.tooltip, this.tester.tooltip)
        Yunit.assertEq(this.rememberedValues.desktop, this.tester.desktop)
        Yunit.assertEq(this.rememberedValues.nDesktops, this.tester.nDesktops)
    }

    MOVE_RIGHT_ARG := "i)(\^#|#\^){Right\s+\d*}"

    class Constructor {

        __new() {
            this.outer := new DesktopChangerTest()
        }

        begin() {
            this.outer.begin(this)
        }

        end() {
            this.outer.end()
        }

        testInjectProperties() {
            target := new DesktopChanger(this.dwm
                , this.desktopMapper, this.tooltip)

            Yunit.assertEq(target.dwm, this.dwm)
            Yunit.assertEq(target.desktopMapper, this.desktopMapper)
            Yunit.assertEq(target.tooltip, this.tooltip)
        }

        testDeriveProperties() {
            target := new DesktopChanger(this.dwm
                , this.desktopMapper, this.tooltip)

            Yunit.assertEq(target.desktop, this.desktop)
            Yunit.assertEq(target.nDesktops, this.nDesktops)
        }

        testMakeNoChangesIfAllOk() {
            this.outer.expectNoChanges()

            target := new DesktopChanger(this.dwm
                , this.desktopMapper, this.tooltip)
        }

        testAddDesktopsIfNeeded() {
            nDiff := 5
            this.outer.givenMoreDesktopsWanted(nDiff)

            this.outer.expectAddDesktops(nDiff)

            target := new DesktopChanger(this.dwm
                , this.desktopMapper, this.tooltip)
        }

        testRemoveDesktopsIfNeeded() {
            nDiff := 5
            this.outer.givenMoreDesktopsPresent(nDiff)

            this.outer.expectRemoveDesktops(nDiff)

            target := new DesktopChanger(this.dwm
                , this.desktopMapper, this.tooltip)
        }
    }

    class Resync {

        __new() {
            this.outer := new DesktopChangerTest()
        }

        begin() {
            this.outer.begin(this)

            this.target := new DesktopChanger(this.dwm
                , this.desktopMapper, this.tooltip)
        }

        end() {
            this.outer.end()
        }

        testMakeNoChangesIfAllOk() {
            this.outer.rememberValues(this.target)
            this.outer.expectNoChanges()

            this.target.resync()

            this.outer.assertSameValues(this.target)
        }

        testAddDesktopsIfNeeded() {
            nDiff := 5
            this.outer.givenFewerDesktopsPresent(nDiff)

            this.outer.expectAddDesktops(nDiff)

            this.target.resync()
        }

        testRemoveDesktopIfNeeded() {
            nDiff := 5
            this.outer.givenFewerDesktopsWanted(nDiff)

            this.outer.expectRemoveDesktops(nDiff)

            this.target.resync()
        }
    }
}
