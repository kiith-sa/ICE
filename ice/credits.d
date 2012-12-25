//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Credits dialog.
module ice.credits;


import std.algorithm;
import std.conv;
import std.range;

import dgamevfs._;

import gui2.buttonwidget;
import gui2.guisystem;
import gui2.rootwidget;
import ice.campaign;
import ice.guiswapper;
import util.yaml;


/// Credits dialog.
class Credits: SwappableGUI
{
private:
    // YAML source of the credits.
    static immutable credits_ = 
        "ICE team:\n"
        "  - name: Ferdinand Majerech\n"
        "  - name: Dávid Horváth\n"
        "  - name: Libor Mališ\n"
        "  - name: Tomáš Nguyen\n"
        "Music: \n"
        "  - name: Osmic\n"
        "    link: http://opengameart.org/users/osmic\n"
        "  - name: Alexandr Zhelanov\n"
        "    link: http://opengameart.org/users/alexandr-zhelanov\n"
        "  - name: FoxSynergy\n"
        "    link: http://opengameart.org/users/foxsynergy\n"
        "Libraries used by ICE:\n"
        "  - name: Derelict\n"
        "  - name: SDL\n"
        "  - name: SDL-Mixer\n"
        "  - name: FreeType\n";

    // Root widget of the credits GUI.
    RootWidget creditsGUI_;

    // YAML nodes with credits data; 
    //
    // Multiple nodes can be used to e.g. add credits for a campaign, etc.
    YAMLNode[] creditsData_;

    // True when the credits are first shown after winning a campaign.
    bool wonCampaign_;

    // Reference to the GUI system; to build widgets.
    GUISystem guiSystem_;

public:
    /// Construct a Credits dialog.
    /// 
    /// Params: guiSystem  = A reference to the GUI system (to load widgets with).
    ///         gameDir    = Game data directory.
    ///
    /// Throws: YAMLException on a YAML parsing error.
    ///         VFSException on a filesystem error.
    this(GUISystem guiSystem, VFSDir gameDir)
    {
        creditsData_ ~= loadYAML(credits_);
        guiSystem_ = guiSystem;
        generateCredits();
        super(creditsGUI_);
    }

    /// Called when the player wins a campaign.
    ///
    /// Params:  data = Data describing the campaign victory.
    void wonCampaign(CampaignWinData data)
    {
        wonCampaign_ = true;
        creditsData_ ~= data.campaignCredits;
        generateCredits();
    }

private:
    /// Called when the "close" button is clicked.
    void atClose()
    {
        // Remove any campaign credits.
        creditsData_ = creditsData_[0 .. 1];
        swapGUI_("ice");
    }

    /// Generate credits widgets.
    void generateCredits()
    {
        auto builder = WidgetBuilder(guiSystem_);

        // Credits generation parameters.

        // Widget styles.
        const buttonStyleDefault  = "{borderColor: rgbaC0C0FF60, fontColor:  rgbaA0A0FFC0}";
        const buttonStyleFocused  = "{borderColor: rgbaC0C0FFA0, fontColor:  rgbaC0C0FFC0}";
        const buttonStyleActive   = "{borderColor: rgbaC0C0FFFF, fontColor:  rgbaE0E0FFFF}";
        const labelStyleXLarge    = "{fontColor:   rgbaFFFFFF80, drawBorder: false, " ~
                                    " fontSize: 14, font: orbitron-bold.ttf}";
        const labelStyleLarge     = "{fontColor:   rgbaEFEFFFCF, drawBorder: false, " ~
                                    " fontSize: 12, font: orbitron-medium.ttf}";
        const labelStyleTheEnd    = "{fontColor:   rgbaEFEFFFCF, drawBorder: false, " ~
                                    " fontSize: 14, font: orbitron-medium.ttf}";
        const labelStyleMedium    = "{fontColor:   rgbaFFFFFF80, drawBorder: false, " ~
                                    " fontSize: 12, font: orbitron-medium.ttf}";
        const labelStyleLink      = "{fontColor:   rgbaFFFF8080, drawBorder: false, " ~
                                    " fontSize: 10, font: orbitron-light.ttf}";

        // Heights of widgets and gaps between them.
        const subSectionGap       = 6;
        const subSectionHeader    = 18;
        const subSectionHeaderGap = 5;
        const creditName          = 14;
        const creditNameGap       = 1;
        const creditLink          = 12;
        const creditGap           = 4;

        const headerHeightStr     = to!string(subSectionHeader);
        const nameHeightStr       = to!string(creditName);
        const linkHeightStr       = to!string(creditLink);

        // Y offset of the current subsection.
        uint yOffset = 48;
        // Y offset within current subsection.
        uint subYOffset  = 0;

        // Determine height of a credits subsection.
        uint subSectionHeight(ref YAMLNode subSection)
        {
            uint height = subSectionHeader + subSectionHeaderGap;
            foreach(ref YAMLNode credit; subSection)
            {
                if(credit.containsKey("name"))
                {
                    height += creditName;
                    height += creditNameGap;
                }
                if(credit.containsKey("link"))
                {
                    height += creditLink;
                }
                height += creditGap;
            }
            height += subSectionGap;
            return height;
        }

        // Generate a single credits item.
        void buildCreditsItem(ref WidgetBuilder b, ref YAMLNode credit)
        {
            if(credit.containsKey("name"))
            {
                auto subYOffsetStr = to!string(subYOffset);
                const name = credit["name"].as!string;
                b.buildWidget!"label"((ref WidgetBuilder b)
                {
                    b.style("default", labelStyleMedium);
                    b.layout("{x: pLeft, y: 'pTop + " ~ subYOffsetStr ~ "'," ~ 
                             " w: pWidth, h: " ~ nameHeightStr ~ "}");
                    b.widgetParams("{text: '" ~ name ~ "'}");
                });
                subYOffset += creditName;
                subYOffset += creditNameGap;
            }
            if(credit.containsKey("link"))
            {
                auto subYOffsetStr = to!string(subYOffset);
                subYOffset += creditLink;
                const link = credit["link"].as!string;
                b.buildWidget!"label"((ref WidgetBuilder b)
                {
                    b.style("default", labelStyleLink);
                    b.layout("{x: pLeft, y: 'pTop + " ~ subYOffsetStr ~ "'," ~ 
                             " w: pWidth, h: " ~ linkHeightStr ~ "}");
                    b.widgetParams("{text: '" ~ link ~ "'}");
                });
            }

            subYOffset += creditGap;
        }

        // Generate a subsection of the credits.
        void buildSubSection
            (ref WidgetBuilder b, const string subSectionName, ref YAMLNode subSection)
        {
            subYOffset       = 0;
            const height     = subSectionHeight(subSection);
            const heightStr  = to!string(height);
            const yOffsetStr = to!string(yOffset);
            // (Invisible) container of the subsection.
            b.buildWidget!"container"((ref WidgetBuilder b)
            {
                auto subYOffsetStr = to!string(subYOffset);
                b.style("default", labelStyleLarge);
                b.layout("{x: 'pLeft + 16', y: 'pTop + " ~ yOffsetStr ~ "'," ~
                         " w: 'pWidth - 32', h: " ~ heightStr ~ "}");
                // Subsection header.
                b.buildWidget!"label"((ref WidgetBuilder b)
                {
                    b.style("default", labelStyleLarge);
                    b.layout("{x: pLeft, y: 'pTop + " ~ subYOffsetStr ~ "'," ~ 
                             " w: pWidth, h: " ~ headerHeightStr ~ "}");
                    b.widgetParams("{text: '" ~ subSectionName ~ "'}");
                });
                subYOffset += subSectionHeader + subSectionHeaderGap;

                // Credits items themselves.
                foreach(ref YAMLNode credit; subSection)
                {
                    buildCreditsItem(b, credit);
                }

            });
            yOffset += height;
        }

        // Root credits widget (main container).
        builder.buildWidget!"root"((ref WidgetBuilder b)
        {
            b.styleManager("line");
            b.layoutManager("boxManual");
            b.style("default", "{backgroundColor: rgba000000FF}");
            b.layout("{x: 'pLeft + 96', y: 'pTop + 16'," ~ 
                     " w: 'pWidth - 192', h: 'pHeight - 32'}");

            // Close button.
            b.buildWidget!"button"((ref WidgetBuilder b)
            {
                b.name = "close";
                b.style("default", buttonStyleDefault);
                b.style("focused", buttonStyleFocused);
                b.style("active",  buttonStyleActive);
                b.layout("{x: 'pLeft + pWidth / 2 - 72', y: 'pBottom - 32'," ~
                        " w: 144, h: 24}");
                b.widgetParams("{text: Close}");
            });

            // "Credits"/"The End" (after winning a campaign) label.
            b.buildWidget!"label"((ref WidgetBuilder b)
            {
                b.style("default", labelStyleXLarge);
                b.layout("{x: 'pLeft + pWidth / 2 - 64', y: 'pTop + 8'," ~ 
                         " w: 128, h: 24}");
                b.widgetParams(wonCampaign_ ? "{text: The End.}" : "{text: Credits}");
            });

            // Credits themselves.
            foreach(ref section; creditsData_.retro)
            {
                foreach(string subSectionName, ref YAMLNode subSection; section)
                {
                    buildSubSection(b, subSectionName, subSection);
                }
            }
        });


        creditsGUI_ = cast(RootWidget)builder.builtWidgets.back;
        creditsGUI_.close!ButtonWidget.connect(&atClose);
        rootWidget = creditsGUI_;
    }
}
